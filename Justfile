set unstable := true

nix := require("nix")
nixos-anywhere := require("nixos-anywhere")
colmena := require("colmena")

alias b := build-vps
alias bv := build-vps
alias d := deploy-vps
alias dv := deploy-vps
alias f := format

# Builds the VPS NixOS configuration
[group("NixOS")]
build-vps:
    {{ colmena }} apply --on vps --keep-result build

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
        --kexec "$KEXEC_PATH"/nixos-kexec-installer-noninteractive-x86_64.tar.gz \
        --generate-hardware-config nixos-facter ./nixos/hosts/vps/facter.json \
        --extra-files "$TMP_DIR"/nixos-anywhere-extras \
        --target-host "{{ ssh-host }}"

# Formats the entire project using treefmt-nix
[group("Project")]
format:
    {{ nix }} fmt
