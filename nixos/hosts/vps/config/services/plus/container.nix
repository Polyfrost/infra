{
    lib,
    inputs,
    system,
    ips,
    ...
}:
{
    systemd.services.plus = {
        wantedBy = [ "multi-user.target" ];

        environment = {
            BIND_ADDR = "[::]:8080";
            CLIENT_IP_SOURCE = "XRealIp";
            DATABASE_URL = "postgresql://plus@[${ips.v6.containers.postgres}]:5432/plus";
            S3_BUCKET_NAME = "plus";
            S3_BUCKET_REGION = "auto";
            RUST_LOG = "debug,sea_orm=debug,sqlx=warn";
        };

        serviceConfig = {
            EnvironmentFile = "/run/host/credentials/plus.secrets.env";

            User = "plus";
            Group = "plus";
            DynamicUser = true;

            ExecStart = [ "${lib.getExe inputs.plus.packages.${system}.default} serve" ];
        };
    };
}
