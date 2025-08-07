{
    custom.nixos-containers.containers.backend = {
        config = ./container.nix;

        dependencies = [ "container@reposilite.service" ];
    };
}
