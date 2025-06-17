{ ips, ... }:
{
    services.reposilite = {
        enable = true;
        database = {
            type = "postgres";
            host = ips.postgres;
        };
        settings = {
            hostname = "0.0.0.0";
            port = 8080;
            sslEnabled = false;

            defaultFrontend = true;
            compressionStrategy = "gzip";
        };
    };
}
