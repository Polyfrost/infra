# This module provides some more convienient options for sepecifying tailscale options
{ lib, config, ... }:
{
    options = {
        services.tailscale.custom = {
            enableSsh = lib.mkEnableOption "tailscale SSH";
            acceptDns = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Whether or not to accept the tailnet's DNS configuration";
            };
            acceptRoutes = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether or not to accept the tailnet's subnet router configurations";
            };
            advertiseExitNode = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether or not to allow using this device as an exit node";
            };
            advertiseRoutes = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "A list of subnets to advertise to the tailnet";
            };
            advertiseTags = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "A list of tags (without the tag: prefix) to assign to this device";
            };
        };
    };

    config =
        let
            cfg = config.services.tailscale.custom;
        in
        lib.mkIf (config.services.tailscale.enable) {
            services.tailscale.extraUpFlags = [
                "--ssh=${lib.boolToString cfg.enableSsh}"
                "--accept-dns=${lib.boolToString cfg.acceptDns}"
                "--accept-routes=${lib.boolToString cfg.acceptRoutes}"
                "--advertise-exit-node=${lib.boolToString cfg.advertiseExitNode}"
            ]
            ++ (lib.optional (
                (builtins.length cfg.advertiseRoutes) > 0
            ) "--advertise-routes=${builtins.concatStringsSep "," cfg.advertiseRoutes}")
            ++ (lib.optional ((builtins.length cfg.advertiseTags) > 0)
                "--advertise-tags=${builtins.concatStringsSep "," (builtins.map (t: "tag:" + t) cfg.advertiseTags)}"
            );
        };
}
