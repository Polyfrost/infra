{ config, lib, ... }:
let
    instances = {
        "website" = {
            flakeInput = "website";
            serviceName = "polyfrost-website";
            secret = "website/secrets.env";
            credential = "website.secrets.env";
        };

        # Only serves /projects/oneclient, routed by caddy
        "website-redesign" = {
            flakeInput = "website-redesign";
            serviceName = "polyfrost-website-redesign";
            secret = "website-redesign/secrets.env";
            credential = "website-redesign.secrets.env";
        };
    };
in
{
    config = lib.mkMerge (
        [
            {
                sops.templates."website/secrets.env".content = ''
                    GITHUB_PAT=${config.sops.placeholder."website/github_pat"}
                '';

                sops.templates."website-redesign/secrets.env".content = ''
                    GITHUB_TOKEN=${config.sops.placeholder."website/github_pat"}
                '';
            }
        ]
        ++ lib.mapAttrsToList (name: instance: {
            custom.nixos-containers.containers.${name} = {
                config = ./container.nix;

                secrets = [ instance.secret ];

                specialArgs.websiteInstance = instance;
            };
        }) instances
    );
}
