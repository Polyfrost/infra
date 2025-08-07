{
    pkgs,
    lib,
    config,
    options,
    customUtils,
    self,
    system,
    inputs,
    ...
}:
let
    moduleType = lib.types.deferredModule;
    cfg = config.custom.nixos-containers;
in
{
    imports = [ ./networking.nix ];

    options = {
        custom.nixos-containers = {
            sharedModules = lib.mkOption {
                description = "The NixOS modules to apply to all containers created with `custom.nixos-containers.containers`";
                default = [ ];
                type = lib.types.listOf moduleType;
            };

            containers = lib.mkOption {
                description = "An attrset including containers to create";
                default = { };
                type = lib.types.attrsOf (
                    lib.types.submodule {
                        options = {
                            config = lib.mkOption {
                                description = ''
                                    The NixOS configuration to activate inside of the container.
                                '';
                                type = moduleType;
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

                            forwardedPorts = lib.genAttrs [ "tcp" "udp" ] (
                                protocol:
                                lib.mkOption {
                                    description = "A list of ${protocol} port numbers that should be forwarded to this container";
                                    default = [ ];
                                    type = lib.types.listOf lib.types.port;
                                }
                            );
                        };
                    }
                );
            };
        };
    };

    config = {
        custom.nixos-containers.sharedModules = [
            {
                system.stateVersion = "25.05";

                nixpkgs.pkgs = pkgs;
                nix.settings.experimental-features = [
                    "nix-command"
                    "flakes"
                ];

                networking.firewall.enable = false;
                networking.useHostResolvConf = false;
                services.resolved.enable = true;
            }
        ];

        systemd.tmpfiles.settings."10-custom-containers" = builtins.listToAttrs (
            builtins.foldl' (
                acc: containerCfg:
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
                ) (builtins.attrNames containerCfg.persistentDirs)
            ) [ ] (builtins.attrValues cfg.containers)
        );

        systemd.services = lib.mapAttrs' (
            name: { dependencies, ... }: lib.nameValuePair "container@${name}" { after = dependencies; }
        ) cfg.containers;

        containers = builtins.mapAttrs (name: containerCfg: {
            config.imports = [ containerCfg.config ] ++ cfg.sharedModules;

            autoStart = true;

            # Harden the container by resetting filesystem each restart, isolating network to a bridge,
            # and running all programs inside the container as unprivileged host system users
            ephemeral = true;
            privateNetwork = true;
            privateUsers = "pick";
            hostBridge = "br0";
            localAddress = "${cfg.networking.addresses.v4.containers.${name}}/24";
            localAddress6 = "${cfg.networking.addresses.v6.containers.${name}}/64";
            hostAddress = cfg.networking.addresses.v4.host;
            hostAddress6 = cfg.networking.addresses.v6.host;

            specialArgs = {
                ips = cfg.networking.addresses;
                inherit
                    customUtils
                    self
                    inputs
                    system
                    ;
            }
            // containerCfg.specialArgs;

            bindMounts = lib.mapAttrs' (
                mountName: value:
                lib.nameValuePair value {
                    hostPath = "/var/lib/containers-persistent/${mountName}";
                    mountPoint = value + (if config.containers.${name}.privateUsers == "pick" then ":idmap" else "");
                    isReadOnly = false;
                }
            ) containerCfg.persistentDirs;

            forwardPorts =
                let
                    mkForwards =
                        protocol:
                        builtins.map (port: {
                            containerPort = port;
                            hostPort = port;
                            inherit protocol;
                        }) containerCfg.forwardedPorts.${protocol};
                in
                (mkForwards "tcp") ++ (mkForwards "udp");

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
            ) containerCfg.secrets;
        }) cfg.containers;
    };
}
