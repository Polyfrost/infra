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

            <webhooks>
                Include ${config.sops.templates."hydra/webhooks.conf".path}
            </webhooks>
        '';
        debugServer = true;
    };

    systemd.services.hydra-init = {
        bindsTo = [ "container@postgres.service" ];
        after = [ "container@postgres.service" ];
    };

    sops.templates."hydra/webhooks.conf" = {
        owner = "hydra";
        group = "hydra";
        mode = "0440";

        content = ''
            <github>
                secret = ${config.sops.placeholder."hydra/github_webhook_secret"}
            </github>
        '';
    };
}
