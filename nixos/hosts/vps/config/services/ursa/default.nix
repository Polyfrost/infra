# Make a container for each ursa instance hosted
# Rules are stored in ./rules/${name}/*.json, and
# a sops secret ursa/tokens/${name} must exist
#
# NOTE: IPs must still be allocated independently
{ config, lib, ... }:
{
    config =
        let
            instances = [
                "hytils"
                "dsm"
                "pss"
            ];
        in
        lib.mkMerge (
            builtins.map (name: {
                sops.secrets."ursa/tokens/${name}" = { };

                custom.containers."ursa-minor-${name}" = {
                    entrypoint = ./container.nix;

                    secrets = [
                        {
                            sops = "ursa/${name}.env";
                            systemd = "ursa-secrets.env";
                        }
                    ];

                    specialArgs = {
                        ursaVariant = name;
                    };
                };

                sops.templates."ursa/${name}.env".content = ''
                    URSA_SECRET=${config.sops.placeholder."ursa/secret"}
                    URSA_HYPIXEL_TOKEN=${config.sops.placeholder."ursa/tokens/${name}"}
                '';
            }) instances
        );
}
