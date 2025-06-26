{
    custom.containers.caddy = {
        entrypoint = ./container.nix;

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
