{ inputs, system, ... }:
{
    services.ursa-minor = {
        enable = true;
        package = inputs.ursa-minor.defaultPackage.${system}.override {
            buildNoDefaultFeatures = true; # Disable NEU-specific features when building
        };

        tokenFile = "ursa.hypixel_token";
    };
}
