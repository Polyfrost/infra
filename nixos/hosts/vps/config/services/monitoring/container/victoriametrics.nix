{ ips, lib, ... }:
{
    services.victoriametrics = {
        enable = true;
        listenAddress = "0.0.0.0:8081";

        retentionPeriod = "4w";

        # TODO: HTTP Basic auth?
        extraOptions = [
            "-http.disableResponseCompression" # Don't bother, its all internally routed anyways
            "-selfScrapeInterval=10s" # Add VictoriaMetrics' metrics to the scraping
        ];

        prometheusConfig = {
            global.scrape_interval = "10s"; # 1m is quite long, especially considering we aren't monitoring much

            scrape_configs = [
                {
                    job_name = "grafana";
                    metrics_path = "/metrics";
                    static_configs = [ { targets = [ "127.0.0.1:8080" ]; } ];
                }
                {
                    job_name = "victoria-logs";
                    metrics_path = "/metrics";
                    static_configs = [ { targets = [ "127.0.0.1:8082" ]; } ];
                }
                {
                    job_name = "node-exporter";
                    metrics_path = "/metrics";
                    static_configs = [ { targets = [ "${ips.host}:9100" ]; } ];
                }
                {
                    job_name = "postgres";
                    metrics_path = "/metrics";
                    static_configs = [ { targets = [ "${ips.containers.postgres}:9187" ]; } ];
                }
                {
                    job_name = "reposilite";
                    metrics_path = "/metrics";
                    static_configs = [ { targets = [ "${ips.containers.reposilite}:8080" ]; } ];
                    basic_auth = {
                        username = "prometheus";
                        password = "prometheus";
                    };
                }
                {
                    job_name = "ursa-minor";
                    metrics_path = "/_meta/metrics";
                    static_configs =
                        let
                            ursaIps = builtins.filter ({ name, ... }: lib.hasPrefix "ursa-minor-" name) (
                                lib.attrsToList ips.containers
                            );
                            configs = builtins.map (
                                { name, value }:
                                {
                                    targets = [ "${value}:8080" ];
                                    labels = {
                                        instance = lib.removePrefix "ursa-minor-" name;
                                    };
                                }
                            ) ursaIps;
                        in
                        configs;
                }
            ];
        };
    };
}
