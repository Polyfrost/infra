{ config, ... }:
{
    custom.containers.monitoring = {
        entrypoint = ./container;

        persistentDirs = {
            "monitoring/grafana" = "/var/lib/grafana";
            "monitoring/victoriametrics" = "/var/lib/private/victoriametrics";
        };

        secrets = [ ];
    };

    # Run node exporter on the host for metrics
    services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" "processes" ];
        listenAddress = config.custom.containerIps.host;
    };
}
