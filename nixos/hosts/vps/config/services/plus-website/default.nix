{ lib, ... }:
let
    instances = {
        # Production instance
        # "plus-website" = {
        #     flakeInput = "plus-website";

        #     backendUrl = "https://plus.polyfrost.org";
        # };

        # Staging instance, pointed at the staging backend
        "plus-website-staging" = {
            flakeInput = "plus-website-staging";

            backendUrl = "https://plus-staging.polyfrost.org";
        };
    };
in
{
    config = lib.mkMerge (
        lib.mapAttrsToList (name: instance: {
            custom.nixos-containers.containers.${name} = {
                config = ./container.nix;

                specialArgs.plusWebsiteInstance = instance // {
                    inherit name;
                };
            };
        }) instances
    );
}
