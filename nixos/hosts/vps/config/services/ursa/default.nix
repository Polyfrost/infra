{ ... }:
{
    custom.containers.ursa-minor = {
        entrypoint = ./container.nix;

        persistentDirs = {
            ursa-minor = "/var/lib/private/ursa-minor";
        };

        secrets = [
            "ursa/secret"
            "ursa/tokens/dsm"
            "ursa/tokens/pss"
            "ursa/tokens/hytils"
        ];

        dependencies = [ "container@postgres.service" ];
    };
}
