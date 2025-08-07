{ config, lib, ... }:
let
    containerIps = config.custom.nixos-containers.networking.addresses;
in
{
    systemd.network = {
        networks."50-bridge" = {
            matchConfig.Name = "br0";

            addresses = [
                { Address = "${containerIps.v4.host}/24"; }
                { Address = "${containerIps.v6.host}/64"; }
            ];

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
        firewall.extraInputRules = ''
            ip saddr ${containerIps.v4.containers.monitoring} tcp dport 9100 accept comment "Allow monitoring to access node exporter"
            ip6 saddr ${containerIps.v6.containers.monitoring} tcp dport 9100 accept comment "Allow monitoring to access node exporter"
        '';

        # Add IPv6 entries for the container aliases, NixOS/nixpkgs#427380
        hosts = lib.mapAttrs' (container: ip: {
            name = ip;
            value = [ "${container}.containers" ];
        }) containerIps.v6.containers;
    };

    services.tailscale.extraUpFlags = [
        "--advertise-routes=${containerIps.v4.cidr},${containerIps.v6.cidr}"
        "--snat-subnet-routes=true" # Fix bridge subnet routing
    ];
}
