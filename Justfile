set unstable := true

nix := require("nix")
nixos-anywhere := require("nixos-anywhere")
colmena := require("colmena")
treefmt := require("treefmt")
geoipupdate := require("geoipupdate")
yq := require("yq")

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
