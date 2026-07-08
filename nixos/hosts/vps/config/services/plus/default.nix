{ config, ... }:
{
    custom.nixos-containers.containers.plus = {
        config = ./container.nix;

        secrets = [ "plus/secrets.env" ];

        dependencies = [ "container@postgres.service" ];
    };

    sops.templates."plus/secrets.env".content = ''
        ADMIN_PASSWORD=${config.sops.placeholder."plus/admin_password"}
        STRIPE_SECRET=${config.sops.placeholder."plus/stripe/secret"}
        STRIPE_WEBHOOK_SECRET=${config.sops.placeholder."plus/stripe/webhook_secret"}
        S3_BUCKET_ENDPOINT=${config.sops.placeholder."plus/s3/endpoint"}
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."plus/s3/access_key_id"}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."plus/s3/access_key_secret"}
    '';
}
