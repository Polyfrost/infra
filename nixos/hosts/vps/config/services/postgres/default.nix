{ config, ... }:
{
    custom.nixos-containers.containers.postgres = {
        config = ./container.nix;

        secrets = [
            "backups/sftp/private_key"
            "backups/sftp/known_hosts"
            "backups/passwords/pgbackrest"
        ];

        persistentDirs = {
            postgres = config.containers.postgres.config.services.postgresql.dataDir;
        };
    };
}
