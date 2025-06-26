{
    lib,
    ips,
    pkgs,
    ...
}:
{
    networking.hosts = lib.mapAttrs' (
        name: value: lib.attrsets.nameValuePair value [ "${name}.containers" ]
    ) ips.containers;

    services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
            plugins = [
                # Support
                "github.com/caddy-dns/cloudflare@v0.2.2-0.20250506153119-35fb8474f57d"
                "github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb"
            ];
            hash = "sha256-sY3LlHw85kV/a8Pjpc6J21cY3K8fqBq7KlMfAmyetH0=";
        };

        configFile = ./Caddyfile;
    };

    # Pass secrets through the systemd service's credentials
    systemd.services.caddy = {
        serviceConfig.LoadCredential = [ "cloudflare_api_key:caddy.cloudflare_api_key" ];
        environment = {
            # Provided dynamically to caddy to allow for overrides when testing
            ACME_DIRECTORY = "https://acme-v02.api.letsencrypt.org/directory";
        };
    };
}
