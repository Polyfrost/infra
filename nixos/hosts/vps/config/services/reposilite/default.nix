{ ... }:
{
    custom.containers.reposilite = {
        entrypoint = ./container.nix;

        persistentDirs = {
            reposilite = "/var/lib/reposilite";
        };
    };
}
