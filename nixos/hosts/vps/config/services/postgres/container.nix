{
    lib,
    ips,
    customUtils,
    ...
}:
let
    databases = {
        "grafana" = ips.v6.containers.monitoring;
        "reposilite" = ips.v6.containers.reposilite;
    };
    mkAuthEntry =
        { name, value }:
        {
            # Trust TCP connections from containers to a database & user
            # with their name, without password authentication
            type = "host";
            database = "sameuser";
            user = name;
            address = "${value}/128";
            method = "trust";
        };
in
{
    services.postgresql = {
        enable = true;
        enableJIT = true;
        enableTCPIP = true;

        ensureDatabases = builtins.attrNames databases;

        ensureUsers = builtins.map (name: {
            inherit name;
            ensureDBOwnership = true;
        }) (builtins.attrNames databases);

        authentication = lib.mkForce (
            customUtils.mkPostgresAuthentication (
                [
                    {
                        # Use peer authentication for local connections by the DB superuser
                        type = "local";
                        database = "all";
                        user = "postgres";
                        method = "peer";
                    }
                ]
                ++ (builtins.map mkAuthEntry (lib.attrsToList databases))
            )
        );
    };

    services.prometheus.exporters.postgres = {
        enable = true;
        runAsLocalSuperUser = true;
    };

    services.pgbackrest = {
        enable = true;
        repos.backup = {
            type = "sftp";
            path = "pgbackrest";
            # sftp-host = "";
        };
    };
}
