{ config, lib, ... }:
let
    instances = {
        # Production instance
        "plus" = {
            db = "plus";
            s3Bucket = "plus";

            flakeInput = "plus";

            stripePublic = "pk_live_51TDj2HCtMbq6LoswkfDJtjyt5Wpd9suZP5Q4ThWea0DorKlWQHX0xMxz9T0HMz6N21KJfQleOjVvFa37QQk1Eynq00pHdnPHHa";
            stripeSuccessUrl = "https://store.polyfrost.org/checkout/success";
            stripeCancelUrl = "https://store.polyfrost.org/checkout/cancel";

            corsOrigins = builtins.concatStringsSep "," [
                "https://plus-admin.polyfrost.org"
                "http://localhost:3000"
                "https://store.polyfrost.org"
            ];
        };

        # Staging instance
        "plus-staging" = {
            db = "plus-staging";
            s3Bucket = "plus-staging";

            flakeInput = "plus-staging";

            # Staging uses Stripe sandbox keys
            stripePublic = "pk_test_51To9giE04pyRM44VoanYF3t5LDlrdtxtwHLXTQaxePn7IGmCmUftMIcUCVSoxUn8mxsozpsac8CLCY7WhVf2KbjQ00P45ey2OV";
            stripeSuccessUrl = "https://store-staging.polyfrost.org/checkout/success";
            stripeCancelUrl = "https://store-staging.polyfrost.org/checkout/cancel";

            corsOrigins = builtins.concatStringsSep "," [
                "https://plus-admin-staging.polyfrost.org"
                "http://localhost:3000"
                "https://store-staging.polyfrost.org"
            ];

            extraEnv = {
                OIDC_ISSUER = "https://plus-staging.polyfrost.org/";
                SPECIAL_CHAT_TARGETS = builtins.concatStringsSep "," [
                    "a5331404-0e77-440e-8bef-24c071dac1ae"
                    "f247be7c-5b82-41c6-9148-793ded77e71f"
                ];
                SPECIAL_CHAT_AUTO_REPLY = ''hey, we're the owners of oneclient. thank you so much for using our open-source products. if you have any suggestions or questions or issues you're having, you can join our discord at discord.gg/polyfrost. also, you can message us directly here! you can only send 1 message per 3 days, so be wise with what you say (but feel free to send us anything you feel is "dumb", we like hearing stuff like that)'';
            };
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
