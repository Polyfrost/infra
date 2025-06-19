{ config, ... }:
{
    custom.containers.reposilite = {
        entrypoint = ./container.nix;

        persistentDirs = {
            reposilite = config.containers.reposilite.workingDirectory;
        };

        dependencies = [ "container@postgres.service" ];
    };
}
