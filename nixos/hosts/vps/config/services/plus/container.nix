{
    lib,
    inputs,
    system,
    ips,
    plusInstance,
    ...
}:
{
    systemd.services.plus = {
        wantedBy = [ "multi-user.target" ];

        environment = {
            BIND_ADDR = "[::]:8080";
            CLIENT_IP_SOURCE = "XRealIp";
            DATABASE_URL = "postgresql://${plusInstance.db}@[${ips.v6.containers.postgres}]:5432/${plusInstance.db}";

            STRIPE_PUBLIC = plusInstance.stripePublic;
            STRIPE_SUCCESS_URL = plusInstance.stripeSuccessUrl;
            STRIPE_CANCEL_URL = plusInstance.stripeCancelUrl;

            S3_BUCKET_NAME = plusInstance.s3Bucket;
            S3_BUCKET_REGION = "auto";
            RUST_LOG = "debug,sea_orm=debug,sqlx=warn";
        };

        serviceConfig = {
            EnvironmentFile = "/run/host/credentials/${plusInstance.name}.secrets.env";

            User = "plus";
            Group = "plus";
            DynamicUser = true;

            ExecStart = [ "${lib.getExe inputs.plus.packages.${system}.default} serve" ];
        };
    };
}
