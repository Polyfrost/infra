{ config, ... }:
{
    custom.nixos-containers.containers.vector = {
        config = ./container.nix;

        secrets = [ "vector/maxmind_license_key" ];

        persistentDirs = {
            vector = "/var/lib/private/vector";
            geoip = "/var/lib/geoip";
        };

        specialArgs = {
            hostConfig = config;
        };
    };
}
