{
    custom.containers.reposilite = {
        entrypoint = ./container.nix;

        dependencies = [ "container@postgres.service" ];

        persistentDirs = {
            reposilite = "/var/lib/reposilite";
        };
    };
}
