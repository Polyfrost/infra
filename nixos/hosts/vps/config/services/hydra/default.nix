{ config, pkgs, lib, ... }:
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

            <runcommand>
                job = infra:release:vps
                command = ln -s $HYDRA_JSON /var/lib/hydra/infra-release-vps.json && systemctl start hydra-nixos-deploy.service
            </runcommand>
        '';
    };

    security.polkit.extraConfig = ''
        // Allow hydra-queue-runner to run the deployment unit
        polkit.addRule(function(action, subject) {
            if (
                action.id == "org.freedesktop.systemd1.manage-units"
                && action.lookup("unit") == "hydra-nixos-deploy.service"
                && subject.user == "hydra-queue-runner"
            ) {
                return polkit.Result.YES;
            }
        });
    '';
    systemd.services.hydra-nixos-deploy = {
        script = ''
            cat /var/lib/hydra/infra-release-vps.json
        '';

        serviceConfig = {
            User = "root";
            Group = "root";
            Type = "oneshot";
        };
    };

    environment.etc."hydra/infra.spec.json".source = ./infra.spec.json;

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
