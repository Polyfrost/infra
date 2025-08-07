{ pkgs, ips, ... }:
{
    services.reposilite = {
        enable = true;

        database = {
            type = "postgresql";
            host = "[${ips.v6.containers.postgres}]";
            user = "reposilite";
            # This is necessary so reposilite doesn't complain about
            # the missing password, though if postgres doesn't require
            # a password then it still works
            passwordFile = pkgs.writeText "reposilite-db-password" "PLACEHOLDER";
        };

        plugins = with pkgs.reposilitePlugins; [ prometheus ];

        settings = {
            hostname = "0.0.0.0";
            port = 8080;
            sslEnabled = false;

            defaultFrontend = true;
            compressionStrategy = "gzip";
        };
    };

    systemd.services.reposilite.environment = {
        REPOSILITE_PROMETHEUS_USER = "prometheus";
        REPOSILITE_PROMETHEUS_PASSWORD = "prometheus";
    };
}
