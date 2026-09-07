set unstable := true

nix := require("nix")
nix-store := require("nix-store")
nixos-anywhere := require("nixos-anywhere")
colmena := require("colmena")
treefmt := require("treefmt")
geoipupdate := require("geoipupdate")
yq := require("yq")

# SSH target used to build the handful of x86_64-linux derivations that a
# non-Linux machine cannot produce itself. See the `seed-ifd` recipe.
linux-host := "root@polyfrost-vps"

_default:
    @just --list

alias b := build-vps
alias bv := build-vps
alias bvq := build-vps-qemu
alias r := rebuild-vps
alias rv := rebuild-vps
alias d := deploy-vps
alias dv := deploy-vps
alias t := test-vps
alias tv := test-vps
alias sv := secrets-vps
alias si := seed-ifd
alias f := format

# Builds the VPS NixOS configuration
[group("NixOS")]
build-vps *args="":
    {{ colmena }} apply --on vps --keep-result{{ if args != "" { " " + args } else { "" } }} build

# Builds the VPS NixOS configuration (QEMU test version)
[group("NixOS")]
build-vps-qemu *args="":
    {{ nix }} build --out-link .gcroots/vps-vm -L{{ if args != "" { " " + args } else { "" } }} '.#nixosConfigurations.vps.config.system.build.vmWithSecrets'

# Applies the VPS NixOS configuration
[group("NixOS")]
rebuild-vps *args="":
    {{ colmena }} apply --on vps --keep-result{{ if args != "" { " " + args } else { "" } }} switch

# Skips the local x86_64-under-Rosetta build and the closure upload entirely --
# the VPS substitutes straight from the caches at datacenter bandwidth. Use this
# when the local build is the bottleneck (big rebuild, poor uplink).
#
# NOT the default on purpose: the VPS is 3 cores / 4GiB RAM and also runs
# Hydra, Postgres and the production services. A large from-source build there
# can push it into swap and disrupt them.

# Applies the VPS NixOS configuration, building on the VPS instead of locally
[group("NixOS")]
rebuild-vps-remote *args="":
    {{ colmena }} apply --on vps --build-on-target --keep-result{{ if args != "" { " " + args } else { "" } }} switch

# Applies the VPS (QEMU) NixOS configuration
[group("NixOS")]
rebuild-qemu *args="":
    ssh-keygen -R polyfrost-vps-qemu-test
    {{ colmena }} apply --on vps-qemu --keep-result{{ if args != "" { " " + args } else { "" } }} switch

# Uses nixos-anywhere to deploy the VPS NixOS configuration
[group("NixOS")]
[script("bash")]
deploy-vps ssh-host:
    set -euo pipefail

    echo "{{ BOLD }}{{ GREEN }}Fetching kexec image...{{ NORMAL }}"

    KEXEC_PATH=$({{ nix }} build --no-link --print-out-paths .#kexec-image)

    echo "{{ BOLD }}{{ GREEN }}Using nixos-anywhere w/ kexec image...{{ NORMAL }}"

    # Create a directory in the format nixos-anywhere wants to deploy the sops-nix key
    TMP_DIR=$(mktemp -d)
    trap 'echo -e "\n{{ BOLD }}{{ GREEN }}Cleaning up...{{ NORMAL }}"; rm -rf -- "$TMP_DIR"' EXIT

    mkdir "$TMP_DIR"/nixos-anywhere-extras

    mkdir -p "$TMP_DIR"/nixos-anywhere-extras/var/lib/sops-nix/
    cp nixos/hosts/vps/age.txt "$TMP_DIR"/nixos-anywhere-extras/var/lib/sops-nix/key.txt

    # Actually install NixOS
    {{ nixos-anywhere }} \
        --flake .#vps \
        --kexec "$KEXEC_PATH"/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz \
        --generate-hardware-config nixos-facter ./nixos/hosts/vps/facter.json \
        --extra-files "$TMP_DIR"/nixos-anywhere-extras \
        --target-host "{{ ssh-host }}"

# Runs a QEMU virtualized version of the nixos configuration
[group("NixOS")]
test-vps:
    {{ nix }} run -L '.#nixosConfigurations.vps.config.system.build.vmWithSecrets'

[group("NixOS")]
[script("bash")]
seed-ifd host=linux-host:
    set -uo pipefail

    ATTR='.#nixosConfigurations.vps.config.system.build.toplevel.drvPath'
    ROOT_DIR=".gcroots/ifd"
    mkdir -p "$ROOT_DIR"

    # Each round can uncover IFD nested inside the previous round's output.
    for attempt in $(seq 1 10); do
        echo "{{ BOLD }}{{ GREEN }}Evaluating (round $attempt)...{{ NORMAL }}"

        if ERR=$({{ nix }} eval --raw "$ATTR" 2>&1 >/dev/null); then
            echo "{{ BOLD }}{{ GREEN }}Evaluates locally, nothing left to seed.{{ NORMAL }}"
            exit 0
        fi

        DRVS=$(grep -E "Cannot build|required to build" <<< "$ERR" \
            | grep -oE "/nix/store/[0-9a-z]{32}-[^']+\.drv" \
            | sort -u)

        if [ -z "$DRVS" ]; then
            echo "$ERR" >&2
            echo "{{ BOLD }}{{ RED }}Evaluation failed for a reason other than a missing IFD build.{{ NORMAL }}" >&2
            exit 1
        fi

        echo "{{ BOLD }}{{ GREEN }}Building on {{ host }}:{{ NORMAL }}"
        printf '  %s\n' $DRVS

        {{ nix }} copy --to "ssh-ng://{{ host }}" --derivation $DRVS || exit 1
        OUTS=$(ssh "{{ host }}" nix-store --realise $DRVS) || exit 1
        {{ nix }} copy --no-check-sigs --from "ssh-ng://{{ host }}" $OUTS || exit 1

        # Without a root these get collected again on the next `nix-collect-garbage`
        # and every subsequent evaluation has to round-trip to the target.
        for out in $OUTS; do
            {{ nix-store }} --realise --indirect --add-root "$ROOT_DIR/$(basename "$out")" "$out" >/dev/null || exit 1
        done
    done

    echo "{{ BOLD }}{{ RED }}Still not evaluating after 10 rounds, giving up.{{ NORMAL }}" >&2
    exit 1

[group("NixOS")]
[script("bash")]
builder:
    set -euo pipefail
    STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/darwin-builder"
    mkdir -p "$STATE_DIR"
    cd "$STATE_DIR"
    # Without this the guest has no CA bundle, so it can't verify cache.nixos.org
    # and substitutes nothing -- every path is pushed over the vsock from the host
    # instead. The vzvm wrapper only forwards the certs if this is set at launch.
    export NIX_SSL_CERT_FILE="${NIX_SSL_CERT_FILE:-/etc/ssl/cert.pem}"
    {{ nix }} run '{{ justfile_directory() }}#linux-builder'

# Opens an editor for the NixOS sops secrets
[group("NixOS")]
secrets-vps $EDITOR="zeditor --wait":
    sops nixos/hosts/vps/sops.yaml

# Formats the entire project using treefmt-nix
[group("Project")]
format *args="":
    {{ treefmt }}{{ if args != "" { " " + args } else { "" } }}

# Downloads the MaxMind geoip database(s) locally
[group("project")]
download-geoip:
    #!/usr/bin/env bash
    alias yq="{{ yq }}"
    alias geoipupdate="{{ geoipupdate }}"
    DB_DIR="nixos/hosts/vps/config/services/vector/geoip"

    # Clear the database directory
    rm -rf "$DB_DIR"
    mkdir "$DB_DIR"

    # Get the license key and account ID
    SECRETS="$(sops decrypt nixos/hosts/vps/sops.yaml)"
    MAXMIND_LICENSE_KEY="$(yq -r .vector.maxmind_license_key <<< "$SECRETS")"
    MAXMIND_ACCOUNT_ID="$(yq -r .vector.maxmind_account_id_unencrypted <<< "$SECRETS")"

    # Make a temporary config file
    CONFIG_FILE="$(mktemp --suffix .GeoIP.conf)"
    trap 'rm -f "$CONFIG_FILE"' EXIT
    echo "LicenseKey $MAXMIND_LICENSE_KEY" >> "$CONFIG_FILE"
    echo "AccountID $MAXMIND_ACCOUNT_ID" >> "$CONFIG_FILE"
    echo "EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country" >> "$CONFIG_FILE"

    # Run the downloader
    geoipupdate \
        --config-file "$CONFIG_FILE" \
        --database-directory "$DB_DIR"
    echo "Successfully downloaded databases into $DB_DIR"
