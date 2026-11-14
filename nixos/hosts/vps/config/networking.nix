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
            flushRuleset = false; # Flushing removes essential rules by tailscale & systemd-nspawns
        };

        # networking is managed by systemd-networkd, disable everything else
        networkmanager.enable = false;
        wireless.enable = false;
        useDHCP = false;
        dhcpcd.enable = false;
    };

    # Setup systemd-networkd on the interface
    systemd.network = {
        enable = true;

        networks."10-ethernet" = {
            matchConfig = {
                Name = "en*";
            };

            networkConfig = {
                # netcup hands out IPv4 via DHCP; IPv6 is static (below)
                DHCP = "ipv4";
                IPv6AcceptRA = "no";

                LinkLocalAddressing = "yes";
                KeepConfiguration = "static";
                LLDP = "no";
                IPv6PrivacyExtensions = "yes";
            };

            # netcup /64 from the SCP; netcup's IPv6 gateway is always fe80::1
            address = [ "2a0a:4cc0:2000:f99b::1/64" ];
            gateway = [ "fe80::1" ];

            linkConfig = {
                RequiredForOnline = "yes";
                RequiredFamilyForOnline = "any";
            };
        };
    };
    # Tailscale overlay network configuration
    services.tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        openFirewall = true;

        authKeyFile = config.sops.secrets."tailscale/oauth_key".path;
        authKeyParameters = {
            ephemeral = false;
            preauthorized = true;
        };
        extraUpFlags = [
            "--reset"
            "--operator=ty"
        ];

        custom = {
            enableSsh = true;
            acceptDns = true;
            acceptRoutes = true;
            advertiseTags = [ "server" ];
        };
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
