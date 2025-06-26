{ customUtils, config, ... }:
{
    custom.containerIps = import ./ips.nix { utils = customUtils; };
    custom.externalInterfaces = [ "enp1s0" ];

    systemd.network = {
        networks."50-bridge" = {
            matchConfig.Name = "br0";
            networkConfig = {
                Address = "${config.custom.containerIps.host}/24";
                Gateway = config.custom.containerIps.gateway;
                DHCP = "no";
                IPMasquerade = "both";
                LLDP = "yes";
                EmitLLDP = "customer-bridge";
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

    networking = {
        # Let containers access host ports conditionally
        firewall.extraInputRules =
            let
                ips = config.custom.containerIps;
            in
            ''
                ip saddr ${ips.containers.monitoring} tcp dport 9100 accept comment "Allow monitoring to access node exporter"
            '';
    };

    services.tailscale.extraUpFlags = [
        "--advertise-routes=${config.custom.containerIps.cidr}"
        "--snat-subnet-routes=true" # Fix bridge subnet routing
    ];
}
