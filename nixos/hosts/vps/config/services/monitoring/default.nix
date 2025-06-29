{ config, ... }:
{
    custom.containers.monitoring = {
        entrypoint = ./container;

        persistentDirs = {
            "monitoring/grafana" = "/var/lib/grafana";
            "monitoring/victoriametrics" = "/var/lib/private/victoriametrics";
            "monitoring/victorialogs" = "/var/lib/private/victorialogs";
        };

        dependencies = [ "container@postgres.service" ];

        secrets = [ ];
    };

    # Run node exporter on the host for metrics
    services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [
            "systemd"
            "processes"
        ];
        listenAddress = config.custom.containerIps.host;
    };

    # Configure journald to forward logs to victorialogs
    services.journald.upload = {
        enable = true;
        settings = {
            Upload.URL = "http://${config.custom.containerIps.containers.monitoring}:8082/insert/journald";
        };
    };
}
