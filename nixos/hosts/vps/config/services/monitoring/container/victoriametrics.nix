{ ips, lib, ... }:
{
    services.victoriametrics = {
        enable = true;
        listenAddress = "0.0.0.0:8081";

        retentionPeriod = "4w";

        # TODO: HTTP Basic auth?
        extraOptions = [ "-http.disableResponseCompression" ];

        prometheusConfig = {
            global.scrape_interval = "5s"; # 1m is quite long, especially considering we aren't monitoring much

            scrape_configs = [
                {
                    job_name = "node-exporter";
                    metrics_path = "/metrics";
                    static_configs = [
                        {
                            targets = [ "${ips.host}:9100" ];
                        }
                    ];
                }
                {
                    job_name = "reposilite";
                    metrics_path = "/metrics";
                    static_configs = [
                        {
                            targets = [ "${ips.containers.reposilite}:8080" ];
                        }
                    ];
                    basic_auth = {
                        username = "prometheus";
                        password = "prometheus";
                    };
                }
                {
                    job_name = "ursa-minor";
                    metrics_path = "/_meta/metrics";
                    static_configs = let
                        ursaIps = builtins.filter ({ name, ... }: lib.hasPrefix "ursa-minor-" name) (lib.attrsToList ips.containers);
                        configs = builtins.map ({ name, value }: {
                            targets = [ "${value}:8080" ];
                            labels = {
                                instance = lib.removePrefix "ursa-minor-" name;
                            };
                        }) ursaIps;
                    in configs;
                }
            ];
        };
    };
}
