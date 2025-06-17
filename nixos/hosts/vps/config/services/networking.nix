{ customUtils, config, ... }:
{
    custom.containerIps = import ./ips.nix { utils = customUtils; };

    systemd.network = {
        networks."50-bridge" = {
            matchConfig.Name = "br0";
            networkConfig = {
                DHCP = "no";
                DNS = config.custom.containerIps.gateway;
                Gateway = config.custom.containerIps.gateway;
                Address = "${config.custom.containerIps.host}/24";
            };
            linkConfig.RequiredForOnline = "no";
        };

        netdevs."50-bridge" = {
            netdevConfig = {
                Kind = "bridge";
                Name = "br0";
            };
        };
    };

    networking.nat = {
        enable = true;
        internalInterfaces = [ "br0" ];
        externalInterface = "enp1s0";
    };

    services.tailscale.extraUpFlags = [
        "--advertise-routes=${config.custom.containerIps.cidr}"
        "--snat-subnet-routes=true" # Fix bridge subnet routing
    ];
}
