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

            # Add some extra networking config to fix IPv6
            # By default QEMU uses a site-local IPv6 prefix,
            # which causes the kernel to prefer ULAs such as
            # the bridge network, causing routing problems
            # as the kernel sees the site-local address as
            # non-global while the ULA is global
            export QEMU_NET_OPTS="ipv4=on,ipv6=on,ipv6-net=fd98:e2b9:6ea3::/64,''${QEMU_NET_OPTS:-}"

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
            cp -r "$FLAKE_ROOT"/nixos/hosts/vps/config/services/vector/geoip "$VM_SECRETS_DIR"/geoip

            NIX_EFI_VARS="$TMP/nix-efi-vars.fd"
            export NIX_EFI_VARS

            ${lib.getExe config.system.build.vmWithDisko}
        '';
    };

    virtualisation.vmVariantWithDisko = {
        # Disable qemu graphics so it just uses the same terminal it was started from
        virtualisation.graphics = false;

        # Set known root password for login if there is a problem with other config
        services.getty.autologinUser = "root";
        users.users.root.password = "password";

        # Provide some utilities for testing
        environment = {
            systemPackages = with pkgs; [
                btop
                nmap
                zellij
                bat
                xh
            ];
            shellAliases = {
                q = "systemctl poweroff";
                # Wrapper around xh to disable TLS validation and override polyfrost.{org,cc} DNS
                # to go straight to the local caddy
                ht =
                    let
                        caddyIp = config.custom.nixos-containers.networking.addresses.v6.containers.caddy;
                        subdomains = [
                            "api"
                            "grafana"
                            "repo"
                        ];
                        resolveArgs =
                            (lib.flatten (
                                builtins.map (subdomain: [
                                    "--resolve '${subdomain}.polyfrost.org:[${caddyIp}]'"
                                    "--resolve '${subdomain}.polyfrost.cc:[${caddyIp}]'"
                                ]) subdomains
                            ))
                            ++ [
                                "--resolve 'polyfrost.org:[${caddyIp}]'"
                                "--resolve 'polyfrost.cc:[${caddyIp}]'"
                            ];
                    in
                    "xhs --verify no ${builtins.concatStringsSep " " resolveArgs}";
            };
        };

        # Configure VM specs
        disko.devices.disk.main.imageSize = "8G";
        disko.memSize = 4096;
        virtualisation.cores = 4;

        # Configure hostname so it is apparent on the tailnet this is a testing instance,
        # and set the tailscale node as ephemeral for convienience with testing
        networking.hostName = lib.mkForce "polyfrost-vps-QEMU-TEST";
        services.tailscale = {
            authKeyParameters.ephemeral = lib.mkForce true;
            extraDaemonFlags = [
                "--state=mem:" # Store state in memory, so ephemeral nodes get removed faster
                "--statedir=/var/lib/tailscale" # Necessary for tailscale ssh to work
            ];
        };

        # Be a bit more verbose on the firewall logging
        networking.firewall = {
            logRefusedConnections = true;
            logRefusedPackets = true;
        };

        # Mount the host's secrets into the VM and configure sops to find the key
        sops.age.keyFile = lib.mkForce "/mnt/host-secrets/age.txt";
        systemd.tmpfiles.settings."10-vm-host-secrets" =
            let
                permissions = {
                    user = "root";
                    group = "root";
                };
            in
            {
                "/mnt/host-secrets"."z" = permissions // {
                    mode = "0700";
                };
                "/mnt/host-secrets/age.txt"."z" = permissions // {
                    mode = "0600";
                };
                "/mnt/host-secrets/geoip"."z" = permissions // {
                    mode = "0755";
                };
                "/mnt/host-secrets/geoip/*.mmdb"."z" = permissions // {
                    mode = "0644";
                };
            };
        virtualisation.sharedDirectories = {
            secrets = {
                source = "$VM_SECRETS_DIR"; # Passed from a wrapper script
                target = "/mnt/host-secrets";
                securityModel = "mapped-xattr";
            };
        };

        # When testing, downgrade container UID isolation as it doesn't work
        # when the nix store is mounted as a 9p filesystem
        containers = lib.mkMerge [
            (builtins.mapAttrs (_: _: { privateUsers = lib.mkForce "identity"; }) config.containers)
            {
                # Override the reverse proxy ACME url to avoid ratelimits
                caddy.config.systemd.services.caddy.environment.ACME_DIRECTORY =
                    lib.mkForce "https://acme-staging-v02.api.letsencrypt.org/directory";

                # Disable domain validation in testing, so you don't have to do DNS hacks
                monitoring.config.services.grafana.settings.server.enforce_domain = lib.mkForce false;

                # Override geoip database to use the local one rather than download every time
                # This is to avoid ratelimits when repeatedly restarting the VM for testing
                vector = {
                    bindMounts."/mnt/geoip" = {
                        hostPath = "/mnt/host-secrets/geoip";
                        isReadOnly = true;
                    };
                    config = {
                        services.geoipupdate.enable = lib.mkForce false;
                        systemd.services.geoipupdate.enable = false;
                        systemd.tmpfiles.settings."10-local-geoip" = {
                            "/var/lib/geoip"."C" = {
                                argument = "/mnt/geoip";
                            };
                        };
                    };
                };

                # Make the backends use the production maven server instead of the local one, as the local one
                # isn't populated with artifacts and thus can't be tested on easily
                backend.config.systemd.services = {
                    backend-v1.environment.BACKEND_INTERNAL_MAVEN_URL = lib.mkForce "https://repo.polyfrost.org";
                };
            }
            (
                let
                    containerBackups = {
                        reposilite = [ "reposilite" ];
                    };
                in
                builtins.mapAttrs (container: backups: {
                    config.services.restic.backups = lib.genAttrs backups (backup: {
                        timerConfig = lib.mkForce null;
                        pruneOpts = lib.mkForce [ ];
                    });
                }) containerBackups
            )
        ];

        # Add CPU TSC invariant support to the VM, as it is required by a crate ursa-minor depends on
        virtualisation.qemu.options = [ "-cpu max,invtsc" ];
    };
}
