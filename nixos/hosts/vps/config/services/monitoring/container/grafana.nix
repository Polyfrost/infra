{ pkgs, lib, ... }:
{
    services.grafana = {
        enable = true;

        declarativePlugins = with pkgs.grafanaPlugins; [
            victoriametrics-metrics-datasource
            victoriametrics-logs-datasource
        ];

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

                providers = [
                    {
                        name = "default";
                        options.path = "/etc/grafana-dashboards";
                    }
                ];
            };

            datasources.settings.datasources = [
                {
                    name = "VictoriaMetrics";
                    type = "victoriametrics-metrics-datasource";
                    access = "proxy";
                    url = "http://localhost:8081";
                }
                {
                    name = "VictoriaLogs";
                    type = "victoriametrics-logs-datasource";
                    access = "proxy";
                    url = "http://localhost:8082";
                }
            ];
        };
    };

    environment.etc =
        let
            fetchurlWithPatches =
                args@{ patches, ... }:
                pkgs.fetchurl (
                    (lib.filterAttrs (name: _: name != "patches") args)
                    // {
                        downloadToTemp = true;
                        postFetch = builtins.concatStringsSep "\n" (
                            (builtins.map (patch: "patch $downloadedFile < ${patch}") patches) ++ [ "cp $downloadedFile $out" ]
                        );
                    }
                );
        in
        {
            "grafana-dashboards/node-exporter.json" = {
                source = fetchurlWithPatches {
                    url = "https://grafana.com/api/dashboards/1860/revisions/41/download";
                    hash = "sha256-A6/4QjcMzkry68fSPwNdHq8i6SGwaKwZXVKDZB5h71A=";

                    patches = [ ./patches/node-exporter-full.patch ];
                };
            };
            "grafana-dashboards/postgres-overview.json" = {
                source = fetchurlWithPatches {
                    url = "https://raw.githubusercontent.com/prometheus-community/postgres_exporter/refs/heads/master/postgres_mixin/dashboards/postgres-overview.json";
                    hash = "sha256-RrR+MSjwY8MwjOeyuVYhwYdZMlCOeyDNg55Njm70q1M=";

                    patches = [ ./patches/postgres-overview.patch ];
                };
            };
        };
}
