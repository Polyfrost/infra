{
    sops = {
        defaultSopsFile = ./sops.yaml;
        defaultSopsFormat = "yaml";

        age.keyFile = "/var/lib/sops-nix/key.txt";
        age.generateKey = false;

        secrets = {
            "backups/sftp/user" = { };
            "backups/sftp/host" = { };
            "backups/sftp/known_hosts" = { };
            "backups/sftp/private_key" = { };
            "backups/passwords/restic/reposilite" = { };
            "backups/passwords/restic/polyhelper" = { };
            "backups/passwords/restic/forgejo" = { };
            "backups/passwords/pgbackrest" = { };

            "caddy/cloudflare_api_key" = { };

            "ursa/secret" = { };
            # Individual ursa/tokens/${name} secrets are in ./config/services/ursa/default.nix

            "website/github_pat" = { };

            "vector/maxmind_license_key" = { };

            "tailscale/oauth_key" = { };
            "tailscale/testing_oauth_key" = { };

            "plus/tebex/webhook_secret" = { };
            "plus/tebex/game_server_secret" = { };
            "plus/s3/endpoint" = { };
            "plus/s3/access_key_id" = { };
            "plus/s3/access_key_secret" = { };

            "users/ty/password_hash" = {
                neededForUsers = true;
            };
        };
    };

    # Ensure restrictive permissions on the keyfile
    systemd.tmpfiles.settings."10-sops-nix" = {
        "/var/lib/sops-nix"."d" = {
            user = "root";
            group = "root";
            mode = "700";
        };

        "/var/lib/sops-nix/key.txt"."f" = {
            user = "root";
            group = "root";
            mode = "600";
        };
    };
}
