let
    ips = import ./ips.nix;
in
{
    systemd.network = {
        networks."50-bridge" = {
            matchConfig.Name = "br0";
            networkConfig = {
                DHCP = "no";
                DNS = ips.gateway;
                Gateway = ips.gateway;
                Address = "${ips.host}/24";
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
        "--advertise-routes=${ips.cidr}"
        "--snat-subnet-routes=true" # Fix bridge subnet routing
    ];
}
