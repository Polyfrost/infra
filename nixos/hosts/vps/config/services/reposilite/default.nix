{
    custom.nixos-containers.containers.reposilite = {
        config = ./container.nix;

        dependencies = [ "container@postgres.service" ];

        persistentDirs = {
            reposilite = "/var/lib/reposilite";
        };
    };
}
