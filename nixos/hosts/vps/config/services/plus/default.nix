{ config, lib, ... }:
let
    instances = {
        # Production instance
        "plus" = {
            db = "plus";
            s3Bucket = "plus";

            flakeInput = "plus";

            extraEnv = {
                STRIPE_PUBLIC = "pk_live_51TDj2HCtMbq6LoswkfDJtjyt5Wpd9suZP5Q4ThWea0DorKlWQHX0xMxz9T0HMz6N21KJfQleOjVvFa37QQk1Eynq00pHdnPHHa";
                STRIPE_SUCCESS_URL = "https://store.polyfrost.org/checkout/success";
                STRIPE_CANCEL_URL = "https://store.polyfrost.org/checkout/cancel";
            };

            secretsEnv = ''
                STRIPE_SECRET=${config.sops.placeholder."plus/stripe/secret"}
                STRIPE_WEBHOOK_SECRET=${config.sops.placeholder."plus/stripe/webhook_secret"}
            '';

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

            extraEnv = {
                PAYNOW_STORE_ID = "593560962137595904";
                PAYNOW_RETURN_URL = "https://store-staging.polyfrost.org/checkout/success";
                PAYNOW_CANCEL_URL = "https://store-staging.polyfrost.org/checkout/cancel";
            };

            secretsEnv = ''
                PAYNOW_API_KEY=${config.sops.placeholder."plus-staging/paynow/api_key"}
                PAYNOW_WEBHOOK_SECRET=${config.sops.placeholder."plus-staging/paynow/webhook_secret"}
            '';

            corsOrigins = builtins.concatStringsSep "," [
                "https://plus-admin-staging.polyfrost.org"
                "http://localhost:3000"
                "https://store-staging.polyfrost.org"
            ];
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
                ${instance.secretsEnv}
                S3_BUCKET_ENDPOINT=${config.sops.placeholder."${name}/s3/endpoint"}
                AWS_ACCESS_KEY_ID=${config.sops.placeholder."${name}/s3/access_key_id"}
                AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."${name}/s3/access_key_secret"}
            '';
        }) instances
    );
}
