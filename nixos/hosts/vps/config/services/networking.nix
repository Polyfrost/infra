{
    customUtils,
    config,
    inputs,
    ...
}:
{
    custom.containerIps = import ./ips.nix {
        utils = customUtils;
        inherit inputs;
    };
    custom.externalInterfaces = [ "enp1s0" ];

    systemd.network = {
        networks."50-bridge" = {
            matchConfig.Name = "br0";

            addresses = [
                {
                    Address = "${config.custom.containerIps.v4.host}/24";
                    Scope = "host";
                }
                { Address = "${config.custom.containerIps.v6.host}/64"; }
            ];

            extraConfig = ''
                [IPv6AddressLabel]
                Label=1000
                Prefix=${config.custom.containerIps.v6.cidr}
            '';

            networkConfig = {
                DHCP = "no";
                IPMasquerade = "both";
                LLDP = "yes";
                EmitLLDP = "customer-bridge";
            };

            linkConfig = {
                RequiredForOnline = "yes";
                RequiredFamilyForOnline = "both";
            };
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
                ip saddr ${ips.v4.containers.monitoring} tcp dport 9100 accept comment "Allow monitoring to access node exporter"
                ip6 saddr ${ips.v6.containers.monitoring} tcp dport 9100 accept comment "Allow monitoring to access node exporter"
            '';
    };

    services.tailscale.extraUpFlags = [
        "--advertise-routes=${config.custom.containerIps.v4.cidr},${config.custom.containerIps.v6.cidr}"
        "--snat-subnet-routes=true" # Fix bridge subnet routing
    ];
}
