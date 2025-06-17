{ config, ... }:
{
    custom.containers.postgres = {
        entrypoint = ./container.nix;
        persistentDirs = {
            postgres = config.containers.postgres.config.services.postgresql.dataDir;
        };
    };
}
