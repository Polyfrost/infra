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

            RENDER_SERVICE_URL = "http://127.0.0.1:8090";
            CORS_ORIGINS = plusInstance.corsOrigins;

            # Instance name matches its subdomain (plus, plus-staging)
            OIDC_ISSUER = "https://${plusInstance.name}.polyfrost.org/";

            SPECIAL_CHAT_TARGETS = builtins.concatStringsSep "," [
                "a5331404-0e77-440e-8bef-24c071dac1ae"
                "f247be7c-5b82-41c6-9148-793ded77e71f"
            ];
            SPECIAL_CHAT_AUTO_REPLY = ''hey, we're the owners of oneclient. thank you so much for using our open-source products. if you have any suggestions or questions or issues you're having, you can join our discord at discord.gg/polyfrost. also, you can message us directly here! you can only send 1 message per 3 days, so be wise with what you say (but feel free to send us anything you feel is "dumb", we like hearing stuff like that)'';
        }
        // (plusInstance.extraEnv or { });

        serviceConfig = {
            EnvironmentFile = "/run/host/credentials/${plusInstance.name}.secrets.env";

            User = "plus";
            Group = "plus";
            DynamicUser = true;

            LimitNOFILE = 65536;

            Restart = "on-failure";
            RestartSec = "5s";

            ExecStart = [ "${lib.getExe inputs.${plusInstance.flakeInput}.packages.${system}.default} serve" ];
        };
    };

    systemd.services.plus-render = {
        wantedBy = [ "multi-user.target" ];
        before = [ "plus.service" ];

        environment = {
            PORT = "8090";
            # for chromium
            HOME = "%t/plus-render";
        };

        serviceConfig = {
            User = "plus";
            Group = "plus";
            DynamicUser = true;

            Restart = "on-failure";
            RestartSec = "5s";

            RuntimeDirectory = "plus-render";

            ExecStart = [ "${lib.getExe inputs.${plusInstance.flakeInput}.packages.${system}.render-service}" ];
        };
    };
}
