{ pkgs, ... }:
{
    services.grafana = {
        enable = true;

        declarativePlugins = [ ];

        settings = {
            server = {
                http_addr = "0.0.0.0";
                http_port = 8080;
                enforce_domain = true;
                enable_gzip = false;
                domain = "grafana.polyfrost.org";
            };

            analytics.reporting_enabled = false;
        };

        provision = {
            enable = true;

            dashboards.settings = {
                apiVersion = 1;

                providers = [{
                    name = "default";
                    options.path = "/etc/grafana-dashboards";
                }];
            };

            datasources.settings.datasources = [
                # Add VictoriaMetrics as a prometheus datasource
                {
                    name = "VictoriaMetrics";
                    type = "prometheus";
                    url = "http://localhost:8081";
                }
            ];
        };
    };

    environment.etc."grafana-dashboards/node-exporter.json" = {
        source = pkgs.fetchurl {
            url = "https://grafana.com/api/dashboards/1860/revisions/41/download";
            hash = "sha256-EywgxEayjwNIGDvSmA/S56Ld49qrTSbIYFpeEXBJlTs=";
        };
    };
}
