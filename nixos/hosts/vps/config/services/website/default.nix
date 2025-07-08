{ config, ... }:
{
    custom.containers.website = {
        entrypoint = ./container.nix;

        secrets = [ "website/secrets.env" ];
    };

    sops.templates."website/secrets.env".content = ''
        GITHUB_PAT=${config.sops.placeholder."website/github_pat"}
    '';
}
