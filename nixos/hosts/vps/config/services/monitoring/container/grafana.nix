{
    pkgs,
    lib,
    ips,
    ...
}:
{
    services.grafana = {
        enable = true;

        declarativePlugins = with pkgs.grafanaPlugins; [
            victoriametrics-metrics-datasource
            victoriametrics-logs-datasource
        ];

        settings = {
            server = {
                http_addr = "::";
                http_port = 8080;
                enforce_domain = true;
                enable_gzip = false;
                domain = "grafana.polyfrost.org";
            };

            database = {
                type = "postgres";
                host = "[${ips.v6.containers.postgres}]";
                user = "grafana";
                name = "grafana";
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
                    url = "http://[::1]:8081";
                }
                {
                    name = "VictoriaLogs";
                    type = "victoriametrics-logs-datasource";
                    access = "proxy";
                    url = "http://[::1]:8082";
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
                    url = "https://raw.githubusercontent.com/prometheus-community/postgres_exporter/77e1a0d65a00bc0ec5120e27a0f372d03fec0055/postgres_mixin/dashboards/postgres-overview.json";
                    hash = "sha256-L3jU98XaiKJsrLl4/EbcPi418jJsLVdd2wg8rHhHMvQ=";

                    patches = [ ./patches/postgres-overview.patch ];
                };
            };
        };
}
