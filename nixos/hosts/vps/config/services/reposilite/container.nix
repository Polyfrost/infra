{ pkgs, ... }:
{
    services.reposilite = {
        enable = true;

        database = {
            # Unfortunately the NixOS module does not allow for an external postgres database
            # without authentication, so for now just use sqlite
            type = "sqlite";
        };

        plugins = with pkgs.reposilitePlugins; [
            prometheus
        ];

        extraArgs = [
            "-Dreposilite.prometheus.user=prometheus"
            "-Dreposilite.prometheus.password=prometheus"
        ];

        settings = {
            hostname = "0.0.0.0";
            port = 8080;
            sslEnabled = false;

            defaultFrontend = true;
            compressionStrategy = "gzip";
        };
    };
}
