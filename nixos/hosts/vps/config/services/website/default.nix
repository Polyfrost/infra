{
    custom.containers.website = {
        entrypoint = ./container.nix;

        secrets = [ "website/github_pat" ];
    };
}
