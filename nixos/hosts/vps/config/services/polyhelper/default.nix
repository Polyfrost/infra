# Not containerized to allow ruin to imperatively update the bot
{ pkgs, lib, ... }:
{
    # TODO find a better way to give access to logs
    # But for now victorialogs is exposed anyways (any local
    # user could theoretically query it), so just give
    # direct journalctl access.
    users.users.ruin.extraGroups = [ "systemd-journal" ];

    security.polkit.extraConfig = ''
        // Allow ruin to manage polyhelper
        polkit.addRule(function(action, subject) {
            if (
                action.id == "org.freedesktop.systemd1.manage-units"
                && action.lookup("unit") == "polyhelper.service"
                && subject.user == "ruin"
            ) {
                return polkit.Result.YES;
            }
        });
    '';

    systemd.tmpfiles.settings."10-polyhelper" =
        let
            perms = {
                user = "ruin";
                group = "users";
                mode = "0755";
            };
        in
        {
            "/srv/polyhelper"."d" = perms;
            "/srv/polyhelper/start"."f" = perms // {
                # Initalize with a placeholder script
                argument = ''
                    #!/usr/bin/env bash
                    # An example script can be found at ${./start.example.sh}

                    echo "Placeholder script"
                    sleep infinity
                '';
            };
            "/srv/polyhelper/.env"."f" = perms // {
                mode = "0700"; # Ensure correct perms on the secrets file
            };
        };

    systemd.services.polyhelper = {
        description = "PolyHelper discord bot";
        wantedBy = [ "multi-user.target" ];

        environment = {
            NODE_ENV = "production";
            DB_DIR = "%S/polyhelper/db";
            HOME = "%S/polyhelper";
        };

        script = ''
            source /etc/profile # Without this, the system binaries (like nix) can't be found

            # Copy the source directory to a writable path (should be in memory)
            # Rsync is used as it doesn't stop on permission errors
            ${lib.getExe pkgs.rsync} --recursive \
                /srv/polyhelper/ "$RUNTIME_DIRECTORY" 2>/dev/null || true # Ignore errors
            cd "$RUNTIME_DIRECTORY"

            exec "$RUNTIME_DIRECTORY"/start
        '';

        serviceConfig = {
            EnvironmentFile = "/srv/polyhelper/.env";

            StateDirectory = "polyhelper";
            RuntimeDirectory = "polyhelper";
            WorkingDirectory = "/srv/polyhelper/";

            Restart = "always";

            ProtectSystem = "strict";
            PrivateTmp = true;
            ProtectHome = true;
            DynamicUser = "yes";

            User = "polyhelper";
            Group = "polyhelper";
        };
    };
}
