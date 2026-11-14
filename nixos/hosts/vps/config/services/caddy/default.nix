{
    custom.nixos-containers.containers.caddy = {
        config = ./container.nix;

        persistentDirs = {
            caddy = "/var/lib/caddy";
        };

        secrets = [ "caddy/cloudflare_api_key" ];

        forwardedPorts = {
            tcp = [
                80
                443
            ];
            udp = [ 443 ];
        };
    };

    # Caddy is the front door for everything. On this small host it got pushed
    # into swap at peak traffic and stalled every site, so keep it in RAM and
    # let colder containers swap instead.
    systemd.services."container@caddy".serviceConfig = {
        MemorySwapMax = 0;
        MemoryLow = "1500M";
    };
}
