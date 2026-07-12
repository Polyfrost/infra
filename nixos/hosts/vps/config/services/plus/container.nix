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

        # Wait for eth0 to get its global address before connecting to postgres
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        # Retry with backoff instead of giving up on a transient DB failure.
        startLimitIntervalSec = 0;

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

            Restart = "on-failure";
            RestartSec = "5s";

            ExecStart = [ "${lib.getExe inputs.${plusInstance.flakeInput}.packages.${system}.default} serve" ];
        };
    };
}
