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
}
