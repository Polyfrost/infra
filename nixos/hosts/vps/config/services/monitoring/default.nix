{
    custom.containers.monitoring = {
        entrypoint = ./container;

        persistentDirs = {
            "monitoring/grafana" = "/var/lib/grafana";
            "monitoring/victoriametrics" = "/var/lib/private/victoriametrics";
        };

        secrets = [ ];
    };
}
