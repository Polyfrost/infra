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
    services.prometheus.exporters.node =
        let
            cfg = config.services.prometheus.exporters.node;
        in
        {
            enable = true;
            enabledCollectors = [
                "systemd"
                "processes"
            ];
            # Listen on both ipv4 and ipv6
            listenAddress = config.custom.containerIps.v4.host;
            extraFlags = [
                "--web.listen-address [${config.custom.containerIps.v6.host}]:${builtins.toString cfg.port}"
            ];
        };

    # The service starts too early (before br0 bindable), so add some dependencies
    systemd.services.prometheus-node-exporter = {
        bindsTo = [ "sys-devices-virtual-net-br0.device" ];
        after = [
            "sys-devices-virtual-net-br0.device"
            "network-online.target"
        ];
    };

    # Configure journald to forward logs to victorialogs
    services.journald.upload = {
        enable = true;
        settings = {
            Upload.URL = "http://[${config.custom.containerIps.v6.containers.monitoring}]:8082/insert/journald";
        };
    };
}
