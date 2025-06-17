{ lib, ips, ... }:
{
    services.plausible = {
        enable = true;
        server = {
            baseUrl = "https://analytics.polyfrost.org";
            disableRegistration = "invite_only";
            secretKeybaseFile = "plausible.secret_key_base";
            listenAddress = "0.0.0.0";
            port = 8080;
        };
        mail = {
            email = "plausible@polyfrost.org";
            smtp = {
                user = "plausible@polyfrost.org";
                hostAddr = "smtp.purelymail.com";
                hostPort = 465;
                enableSSL = true;

                passwordFile = "plausible.smtp_password"; # Systemd credential from container
            };
        };
        database = {
            postgres = {
                setup = false;
                dbname = "plausible";
            };
            clickhouse = {
                setup = true;
            };
        };
    };

    systemd.services.plausible.environment.DATABASE_URL =
        lib.mkForce "postgresql://plausible@${ips.containers.postgres}:5432/plausible";
}
