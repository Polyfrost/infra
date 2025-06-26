{ ips, ... }:
{
    services.victoriametrics = {
        enable = true;
        listenAddress = "0.0.0.0:8081";

        retentionPeriod = "4w";

        # TODO: HTTP Basic auth?
        extraOptions = [ "-http.disableResponseCompression" ];

        prometheusConfig = {
            scrape_configs = [
                {
                    job_name = "node-exporter";
                    metrics_path = "/metrics";
                    static_configs = [
                        {
                            targets = [ "${ips.host}:9100" ];
                            labels.type = "node";
                        }
                    ];
                }
                {
                    job_name = "reposilite";
                    metrics_path = "/metrics";
                    static_configs = [
                        {
                            targets = [ "${ips.reposilite}:8080" ];
                        }
                    ];
                }
            ];
        };
    };
}
