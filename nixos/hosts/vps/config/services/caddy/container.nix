{
    lib,
    ips,
    pkgs,
    ...
}:
{
    networking.hosts =
        let
            mkHosts =
                containerIps:
                lib.mapAttrs' (name: value: lib.attrsets.nameValuePair value [ "${name}.containers" ]) containerIps;
        in
        (mkHosts ips.v4.containers) // (mkHosts ips.v6.containers);

    services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
            plugins = [
                # Support
                "github.com/caddy-dns/cloudflare@v0.2.2-0.20250506153119-35fb8474f57d"
                "github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb"
            ];
            hash = "sha256-K2ygIQiIXWl4Y51lzpgWbI3ypWPj1niS+aTwvtLkfvs=";
        };

        configFile = ./Caddyfile;
    };

    # Pass secrets through the systemd service's credentials
    systemd.services.caddy = {
        serviceConfig.LoadCredential = [ "cloudflare_api_key:caddy.cloudflare_api_key" ];
        environment = {
            # Provided dynamically to caddy to allow for overrides when testing
            ACME_DIRECTORY = "https://acme-v02.api.letsencrypt.org/directory";
            VECTOR_URL = "tcp/[${ips.v6.containers.vector}]:9000";
        };
    };
}
