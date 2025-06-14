{ ips, ... }:
{
    services.plausible = {
        enable = true;
        server = {
            baseUrl = "https://analytics.polyfrost.org";
            disableRegistration = "invite_only";
            secretKeybaseFile = "plausible.secret_key_base";
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
                socket = ips.postgres;
                setup = false;
                dbname = "plausible";
            };
            clickhouse = {
                setup = true;
            };
        };
    };
}
