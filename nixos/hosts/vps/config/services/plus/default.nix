{ config, ... }:
{
    custom.nixos-containers.containers.plus = {
        config = ./container.nix;

        secrets = [ "plus/secrets.env" ];

        dependencies = [ "container@postgres.service" ];
    };

    sops.templates."plus/secrets.env".content = ''
        ADMIN_PASSWORD=${config.sops.placeholder."plus/admin_password"}
        TEBEX_WEBHOOK_SECRET=${config.sops.placeholder."plus/tebex/webhook_secret"}
        TEBEX_GAME_SERVER_SECRET=${config.sops.placeholder."plus/tebex/game_server_secret"}
        S3_BUCKET_ENDPOINT=${config.sops.placeholder."plus/s3/endpoint"}
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."plus/s3/access_key_id"}
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."plus/s3/access_key_secret"}
    '';
}
