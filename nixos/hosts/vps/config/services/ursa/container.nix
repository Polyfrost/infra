{
    self,
    inputs,
    system,
    lib,
    ursaVariant,
    ...
}:
{
    imports = [ self.nixosModules.default ];

    services.ursa-minor = {
        enable = true;

        package = inputs.ursa-minor.defaultPackage.${system}.overrideAttrs {
            cargoBuildNoDefaultFeatures = true; # Disable NEU-specific features when building
        };

        settings = {
            address = "::";
            port = 8080;
            rules =
                let
                    rulesDir = ./rules + "/${ursaVariant}";
                    rules = lib.filterAttrs (
                        name: value: (builtins.match "^.+\\.json$" name != null) && value == "regular"
                    ) (builtins.readDir rulesDir);
                in
                lib.mapAttrsToList (name: value: rulesDir + "/${name}") rules;
            allowAnonymous = false;
            tokenLifespan = 3600;
            rateLimitTimeout = 300;
            rateLimitBucket = 20; # TODO collect metrics and reduce if possible

            environmentFile = "/run/host/credentials/ursa-secrets.env";
        };
    };
}
