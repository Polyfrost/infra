{
    custom.containers.backend = {
        entrypoint = ./container.nix;

        dependencies = [ "container@reposilite.service" ];
    };
}
