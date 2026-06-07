{
    lib,
    ips,
    pkgs,
    inputs,
    system,
    ...
}:
{
    networking.hosts =
        let
            mkHosts =
                containerIps:
                lib.mapAttrs' (name: value: lib.attrsets.nameValuePair value [ "${name}.containers" ]) containerIps;
        in
        (mkHosts ips.v4.containers) // (mkHosts ips.v6.containers) // {
            "${ips.v4.host}" = [ "host.containers" ];
            "${ips.v6.host}" = [ "host.containers" ];
        };

    services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
            plugins = [
                # Support
                "github.com/caddy-dns/cloudflare@v0.2.4-0.20260323191214-a8737d095ad5"
                "github.com/WeidiDeng/caddy-cloudflare-ip@v0.0.0-20231130002422-f53b62aa13cb"
            ];
            hash = "sha256-c5Ze/EnmPayYnpbb8zjvcsiNMmQMiiLbmHP2fRluShI=";
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

    systemd.tmpfiles.settings."10-var-www" = {
        "/var/www/plus-admin-dashboard"."L" = {
            argument = "${inputs.plus-admin-dashboard.packages.${system}.default}/share";
        };
    };
}
