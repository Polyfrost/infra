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

            # Prod
            # STRIPE_PUBLIC = "pk_live_51TDj2HCtMbq6LoswkfDJtjyt5Wpd9suZP5Q4ThWea0DorKlWQHX0xMxz9T0HMz6N21KJfQleOjVvFa37QQk1Eynq00pHdnPHHa";
            # STRIPE_SUCCESS_URL = "";
            # STRIPE_CANCEL_URL = "";

            # Sandbox
            STRIPE_PUBLIC = "pk_test_51To9giE04pyRM44VoanYF3t5LDlrdtxtwHLXTQaxePn7IGmCmUftMIcUCVSoxUn8mxsozpsac8CLCY7WhVf2KbjQ00P45ey2OV";
            STRIPE_SUCCESS_URL = "https://polyfrost.org/success_stub";
            STRIPE_CANCEL_URL = "https://polyfrost.org/cancel_stub";

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
