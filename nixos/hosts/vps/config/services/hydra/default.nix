{ config, ... }:
{
    services.hydra = {
        enable = true;
        hydraURL = "https://hydra.polyfrost.org";
        useSubstitutes = true;
        dbi = "dbi:Pg:dbname=hydra;host=${config.custom.nixos-containers.networking.addresses.v6.containers.postgres};user=hydra";
        port = 3000;
        listenHost = "*";
        notificationSender = "hydra@localhost";
        extraConfig = ''
            allow_import_from_derivation = true
        '';
    };
}
