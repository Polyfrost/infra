{ pkgs, lib, config, ... }:
{
    system.build.vmWithSecrets = pkgs.writeShellApplication {
        name = "disko-vm-with-secrets";

        text = ''
            set -x

            # Create a temporary directory to store the final
            VM_SECRETS_DIR="$(mktemp -d)"
            export VM_SECRETS_DIR # Export so it is passed down to the final qemu command
            trap 'rm -rf "$VM_SECRETS_DIR"' EXIT

            # Search up from the current directory for the dir containing flake.nix
            FLAKE_ROOT=""
            while [ "$PWD" != "/" ]; do
                    if test -e flake.nix; then
                        FLAKE_ROOT="$PWD"
                        break
                    fi
                    cd ..
            done

            if [ "$FLAKE_ROOT" == "" ]; then
                >&2 echo -n "Unable to find project root to copy secrets from,"
                >&2 echo " please make sure you are in/under the folder containing flake.nix."

                exit 1
            fi

            cp "$FLAKE_ROOT"/nixos/hosts/vps/age.txt "$VM_SECRETS_DIR"/age.txt

            ${lib.getExe config.system.build.vmWithDisko}
        '';
    };

    virtualisation.vmVariantWithDisko = {
        # Set known root password for login if there is a problem with other config
        services.getty.autologinUser = "root";
        users.users.root.password = "password";

        # Configure image memory & storage allocation
        disko.devices.disk.main.imageSize = "8G";
        disko.memSize = 4096;

        # Configure hostname so it is apparent on the tailnet this is a testing instance
        networking.hostName = lib.mkForce "polyfrost-vps-QEMU-TEST";

        # Correct the hardcoded network interface to be the QEMU one
        networking.nat.externalInterface = lib.mkForce "enp0s3";

        # Mount the host's secrets into the VM and configure sops to find the key
        sops.age.keyFile = lib.mkForce "/mnt/host-secrets/age.txt";
        virtualisation.sharedDirectories = {
            secrets = {
                source = "$VM_SECRETS_DIR"; # Passed from a wrapper script
                target = "/mnt/host-secrets";
                securityModel = "mapped-xattr";
            };
        };
    };
}
