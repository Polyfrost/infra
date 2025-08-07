{ config, ... }:
{
    custom.nixos-containers.containers.postgres = {
        config = ./container.nix;
        persistentDirs = {
            postgres = config.containers.postgres.config.services.postgresql.dataDir;
        };
    };
}
