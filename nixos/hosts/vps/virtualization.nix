{
    pkgs,
    lib,
    config,
    ...
}:
{
    system.build.vmWithSecrets = pkgs.writeShellApplication {
        name = "disko-vm-with-secrets";

        text = ''
            set -x

            # Create a temporary directory to store intermediates
            TMP="$(mktemp -d)"
            trap 'rm -rf "$TMP"' EXIT

            # Make a directory to store secrets in a flat hierarchy for the VM
            VM_SECRETS_DIR="$TMP/secrets"
            mkdir "$VM_SECRETS_DIR"
            export VM_SECRETS_DIR # Export so it is passed down to the final qemu command

            # Give the later steps an out of the way location to store EFI vars, as it defaults to
            # $PWD which is annoying
            NIX_EFI_VARS="$TMP/efi-vars.fd"
            export NIX_EFI_VARS

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

            NIX_EFI_VARS="$TMP/nix-efi-vars.fd"
            export NIX_EFI_VARS

            ${lib.getExe config.system.build.vmWithDisko}
        '';
    };

    virtualisation.vmVariantWithDisko = {
        # Set known root password for login if there is a problem with other config
        services.getty.autologinUser = "root";
        users.users.root.password = "password";

        # Provide some utilities for testing
        environment.systemPackages = with pkgs; [ nmap ];

        # Configure image memory & storage allocation
        disko.devices.disk.main.imageSize = "8G";
        disko.memSize = 4096;

        # Configure hostname so it is apparent on the tailnet this is a testing instance,
        # and set the tailscale node as ephemeral for convienience with testing
        networking.hostName = lib.mkForce "polyfrost-vps-QEMU-TEST";
        services.tailscale.authKeyParameters.ephemeral = lib.mkForce true;

        # Correct the hardcoded network interface to be the QEMU one
        networking.nat.externalInterface = lib.mkForce "eth0";

        # Mount the host's secrets into the VM and configure sops to find the key
        sops.age.keyFile = lib.mkForce "/mnt/host-secrets/age.txt";
        virtualisation.sharedDirectories = {
            secrets = {
                source = "$VM_SECRETS_DIR"; # Passed from a wrapper script
                target = "/mnt/host-secrets";
                securityModel = "mapped-xattr";
            };
        };

        # When testing, downgrade container UID isolation as it doesn't work
        # when the nix store is mounted as a 9p filesystem
        containers = builtins.mapAttrs (_: _: { privateUsers = lib.mkForce "identity"; }) config.containers;
    };
}
