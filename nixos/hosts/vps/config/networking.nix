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
                # Default to no DHCP or RA, this will be changed by drop-in if necessary
                DHCP = "no";
                IPv6AcceptRA = "no";

                LinkLocalAddressing = "yes";
                KeepConfiguration = "static";
                LLDP = "no";
                IPv6PrivacyExtensions = "yes";
            };

            linkConfig = {
                RequiredForOnline = "yes";
                RequiredFamilyForOnline = "any";
            };
        };
    };
    systemd.services.systemd-networkd-hetzner-cloud-setup = {
        description = "Gets network configuration from Hetzner's metadata API and setups up networking";
        wantedBy = [ "multi-user.target" ];

        # This would be much easier if hetzner just supported router advertisements but here we are
        script = ''
            # Wait for the carrier (necessary for hetzner metadata api via link local)
            ${config.systemd.package}/lib/systemd/systemd-networkd-wait-online --operational-state=carrier --ipv4

            # Write drop-in where networkd expects it
            mkdir -p /etc/systemd/network/10-ethernet.network.d
            GENERATED_DROPIN=$(${lib.getExe pkgs.nushell} ${./gen-networkd.nu})
            if [ $? -eq 0 ]; then
                # If success, write generated file and reload networking
                echo "$GENERATED_DROPIN" > /etc/systemd/network/10-ethernet.network.d/hetzner.conf
                networkctl reload
            else
                # If failure, write a replacement fallback "use DHCP" config and use that
                echo -e "[Network]\nDHCP=yes" > /etc/systemd/network/10-ethernet.network.d/hetzner.conf
                networkctl reload
                exit 1 # Ensure failure is noticed
            fi
        '';
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
