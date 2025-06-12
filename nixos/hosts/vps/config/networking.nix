{
    pkgs,
    lib,
    config,
    ...
}:
{
    networking = {
        hostName = "polyfrost-vps";

        firewall = {
            enable = true;
            allowedTCPPorts = [
                80 # Caddy HTTP/1-2
                443 # Caddy HTTPS/1-2
            ];
            allowedUDPPorts = [
                443 # Caddy HTTP/3
            ];
        };
        nftables = {
            enable = true;
            flushRuleset = true;
        };

        # networking is managed by systemd-networkd, disable everything else
        networkmanager.enable = false;
        wireless.enable = false;
        useDHCP = false;
    };

    systemd.network = {
        enable = true;

        networks."10-ethernet" = {
            matchConfig = {
                Name = "en*";
            };

            networkConfig = {
                DHCP = "yes";
                KeepConfiguration = "static";
                IPv6AcceptRA = "yes";
                LLDP = "yes";
            };

            linkConfig.RequiredForOnline = "yes";
        };
    };

    # Tailscale overlay network configuration
    services.tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        openFirewall = true;

        authKeyFile = config.sops.secrets."tailscale/preauth_key".path;
        extraUpFlags = [
            "--reset"
            "--ssh"
            "--accept-dns"
            "--accept-routes"
            "--advertise-tags=tag:server"
            "--operator=ty"
        ];
    };
    systemd.services.tailscaled.environment = {
        LTS_DEBUG_FIREWALL_MODE = "nftables";
    };
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
    services.networkd-dispatcher = {
        enable = true;
        rules."50-tailscale" = {
            onState = [ "routable" ];
            script = ''
                ${lib.getExe pkgs.ethtool} -K "$IFACE" rx-udp-gro-forwarding on rx-gro-list off
            '';
        };
    };
    # Avoid restarting tailscaled during deployment, which causes disconnects while waiting for activation
    systemd.services.tailscaled.restartIfChanged = false;
}
