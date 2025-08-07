{
    custom.nixos-containers.networking = {
        ipAllocations = [
            # All new allocations should go to the end.
            # If any indexes change, the container IPs will also change.
            "caddy"
            "postgres"
            "reposilite"
            "backend-legacy"
            "backend"
            "ursa-minor-hytils"
            "ursa-minor-dsm"
            "ursa-minor-pss"
            "monitoring"
            "website"
            "vector"
        ];

        v4.cidr = "172.25.0.0/24";
        v6 = {
            ulaPrefix = "fd06:f707:1303::/48";
            subnetId = 0;
        };
    };
}
