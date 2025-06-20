{
    pkgs,
    lib,
    config,
    customUtils,
    self,
    system,
    inputs,
    ...
}:
{
    options = {
        # TODO move ips.nix to a proper module
        custom.containerIps = lib.mkOption {
            description = "An attrset containing the IP addresses to be used for containers";
            default = { };
            type = lib.types.attrs;
        };

        custom.containers = lib.mkOption {
            description = "An attrset including containers to create";
            default = { };
            type = lib.types.attrsOf (
                lib.types.submodule {
                    options = {
                        entrypoint = lib.mkOption {
                            description = "A path to the nix entrypoint for the container's configuration";
                            type = lib.types.pathInStore;
                        };

                        persistentDirs = lib.mkOption {
                            description = ''
                                An attrset of paths to persist across container restarts. The name should be a user-friendly
                                name for the host mount, and the value should be the path being persisted inside the container.

                                These mounts can be accessed at `/var/lib/containers-persistent/''${name}`, which is only accessible
                                via root.
                            '';
                            default = { };
                            type = lib.types.attrsOf lib.types.str;
                        };

                        secrets = lib.mkOption {
                            description = ''
                                A list of secret names to pass into the containers. Inside the container, slashes are replaced
                                with periods, i.e. `foo/bar` becomes the systemd credential `foo.bar`.

                                These can be accessed at `/run/host/credentials`, or passed by name to systemd services.
                            '';
                            default = [ ];
                            type = lib.types.listOf (
                                lib.types.either lib.types.str (
                                    lib.types.submodule {
                                        options = {
                                            sops = lib.mkOption {
                                                description = "The name of the SOPS credential to pass into the container";
                                                default = null;
                                                type = lib.types.str;
                                            };
                                            systemd = lib.mkOption {
                                                description = "The name of the systemd credential to provide inside the container";
                                                default = null;
                                                type = lib.types.str;
                                            };
                                        };
                                    }
                                )
                            );
                        };

                        dependencies = lib.mkOption {
                            description = ''
                                A list of systemd unit dependencies that should come up before this container.
                            '';
                            default = [ ];
                            type = lib.types.listOf lib.types.str;
                        };

                        specialArgs = lib.mkOption {
                            description = "An attribute set of extra module arguments to pass inside the container";
                            default = { };
                            type = lib.types.attrs;
                        };
                    };
                }
            );
        };
    };

    config = {
        systemd.tmpfiles.settings."10-custom-containers" = builtins.listToAttrs (
            builtins.foldl' (
                acc: cfg:
                acc
                ++ builtins.map (
                    name:
                    lib.nameValuePair "/var/lib/containers-persistent/${name}" {
                        d = {
                            user = "root";
                            group = "root";
                            mode = "0700";
                        };
                    }
                ) (builtins.attrNames cfg.persistentDirs)
            ) [ ] (builtins.attrValues config.custom.containers)
        );

        systemd.services = lib.mapAttrs' (
            name: { dependencies, ... }: lib.nameValuePair "container@${name}" { after = dependencies; }
        ) config.custom.containers;

        containers = builtins.mapAttrs (name: cfg: {
            config = {
                imports = [ cfg.entrypoint ];

                system.stateVersion = "25.05";
                nixpkgs.pkgs = pkgs;

                nix.settings.experimental-features = [
                    "nix-command"
                    "flakes"
                ];

                networking.firewall.enable = false;
                networking.useHostResolvConf = false;
                services.resolved.enable = true;
            };

            autoStart = true;

            # Harden the container by resetting filesystem each restart, isolating network to a bridge,
            # and running all programs inside the container as unprivileged host system users
            ephemeral = true;
            privateNetwork = true;
            privateUsers = "pick";
            hostBridge = "br0";
            localAddress = "${config.custom.containerIps.containers.${name}}/24";
            hostAddress = config.custom.containerIps.host;

            specialArgs = {
                ips = config.custom.containerIps;
                inherit
                    customUtils
                    self
                    inputs
                    system
                    ;
            } // cfg.specialArgs;

            bindMounts = lib.mapAttrs' (
                mountName: value:
                lib.nameValuePair value {
                    hostPath = "/var/lib/containers-persistent/${mountName}";
                    mountPoint = value + (if config.containers.${name}.privateUsers == "pick" then ":idmap" else "");
                    isReadOnly = false;
                }
            ) cfg.persistentDirs;

            extraFlags = builtins.map (
                secret:
                let
                    secretAttrs =
                        if builtins.typeOf secret == "string" then
                            {
                                systemd = lib.replaceString "/" "." secret;
                                sops = secret;
                            }
                        else
                            secret;
                    isTemplate = builtins.hasAttr secretAttrs.sops config.sops.templates;
                    sopsPath =
                        if isTemplate then
                            config.sops.templates.${secretAttrs.sops}.path
                        else
                            config.sops.secrets.${secretAttrs.sops}.path;
                in
                "--load-credential=${secretAttrs.systemd}:${sopsPath}"
            ) cfg.secrets;
        }) config.custom.containers;
    };
}
