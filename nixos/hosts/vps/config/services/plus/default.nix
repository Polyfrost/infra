{ config, lib, ... }:
let
    instances = {
        # Production instance
        # "plus" = {
        #     db = "plus";
        #     s3Bucket = "plus";

        #     stripePublic = "pk_live_51TDj2HCtMbq6LoswkfDJtjyt5Wpd9suZP5Q4ThWea0DorKlWQHX0xMxz9T0HMz6N21KJfQleOjVvFa37QQk1Eynq00pHdnPHHa";
        #     stripeSuccessUrl = "https://polyfrost.org/success_stub";
        #     stripeCancelUrl = "https://polyfrost.org/cancel_stub";
        # };

        # Staging instance
        "plus-staging" = {
            db = "plus-staging";
            s3Bucket = "plus-staging";

            # Staging uses Stripe sandbox keys
            stripePublic = "pk_test_51To9giE04pyRM44VoanYF3t5LDlrdtxtwHLXTQaxePn7IGmCmUftMIcUCVSoxUn8mxsozpsac8CLCY7WhVf2KbjQ00P45ey2OV";
            stripeSuccessUrl = "https://staging.polyfrost.org/success_stub";
            stripeCancelUrl = "https://staging.polyfrost.org/cancel_stub";
        };
    };
in
{
    config = lib.mkMerge (
        lib.mapAttrsToList (name: instance: {
            custom.nixos-containers.containers.${name} = {
                config = ./container.nix;

                secrets = [ "${name}/secrets.env" ];

                dependencies = [ "container@postgres.service" ];

                specialArgs.plusInstance = instance // {
                    inherit name;
                };
            };

            sops.templates."${name}/secrets.env".content = ''
                ADMIN_PASSWORD=${config.sops.placeholder."${name}/admin_password"}
                STRIPE_SECRET=${config.sops.placeholder."${name}/stripe/secret"}
                STRIPE_WEBHOOK_SECRET=${config.sops.placeholder."${name}/stripe/webhook_secret"}
                S3_BUCKET_ENDPOINT=${config.sops.placeholder."${name}/s3/endpoint"}
                AWS_ACCESS_KEY_ID=${config.sops.placeholder."${name}/s3/access_key_id"}
                AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."${name}/s3/access_key_secret"}
            '';
        }) instances
    );
}
