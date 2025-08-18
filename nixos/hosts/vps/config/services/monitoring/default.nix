{ config, lib, ... }:
let
    containerIps = config.custom.nixos-containers.networking.addresses;
    journaldFwdCfg = {
        # Configure journald to forward logs to victorialogs (provided the contianer exists & has victorialogs enabled)
        systemd.services.systemd-journal-upload = {
            startLimitBurst = 5;
            startLimitIntervalSec = 120;
        };
        services.journald.upload =
            lib.mkIf
                # NOTE: The following is deliberately inheriting the non-containerized `config` value
                (config.containers ? monitoring && config.containers.monitoring.config.services.victorialogs.enable)
                {
                    enable = true;
                    settings = {
                        Upload = {
                            URL = "http://[${containerIps.v6.containers.monitoring}]:8082/insert/journald";
                            NetworkTimeoutSec = "15s";
                        };
                    };
                };
    };
in
{
    # TODO: move everything but custom.containers.monitoring to ./host.nix
    custom.nixos-containers.containers.monitoring = {
        config = ./container;

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
            listenAddress = containerIps.v4.host;
            extraFlags = [ "--web.listen-address [${containerIps.v6.host}]:${builtins.toString cfg.port}" ];
        };

    # The service starts too early (before br0 bindable), so wait for network online
    systemd.services.prometheus-node-exporter = {
        bindsTo = [ "network-online.target" ];
        after = [ "network-online.target" ];
    };

    # Configure journald to forward logs to victorialogs
    imports = [ journaldFwdCfg ];
    custom.nixos-containers.sharedModules = [ journaldFwdCfg ];
}
