{
    custom.containers.vector = {
        entrypoint = ./container.nix;

        secrets = [
            "vector/maxmind_license_key"
            "vector/maxmind_account_id"
        ];

        persistentDirs = {
            vector = "/var/lib/private/vector";
            geoip = "/var/lib/geoip";
        };
    };
}
