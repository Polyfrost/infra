# Not containerized to allow ruin to imperatively update the bot
{
    pkgs,
    lib,
    config,
    ...
}:
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
            HOME = "%t/polyhelper";
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

    # Backups
    sops.templates."backups/polyhelper/repositories/polyhelper".content = ''
        sftp:${config.sops.placeholder."backups/sftp/user"}@${
            config.sops.placeholder."backups/sftp/host"
        }:restic/polyhelper
    '';
    systemd.services.restic-backups-polyhelper.serviceConfig.LoadCredential = [
        "password:${config.sops.secrets."backups/passwords/restic/polyhelper".path}"
        "ssh_private_key:${config.sops.secrets."backups/sftp/private_key".path}"
        "ssh_known_hosts:${config.sops.secrets."backups/sftp/known_hosts".path}"
        "repository:${config.sops.templates."backups/polyhelper/repositories/polyhelper".path}"
    ];
    services.restic.backups.polyhelper =
        let
            credentialsDir = "/run/credentials/restic-backups-polyhelper.service";
        in
        {
            initialize = true;
            createWrapper = false; # Broken due to systemd credentials
            passwordFile = "%d/password";
            repositoryFile = "${credentialsDir}/repository";

            extraOptions =
                let
                    sftpArgs = [
                        "-i ${credentialsDir}/ssh_private_key"
                        "-o UserKnownHostsFile=${credentialsDir}/ssh_known_hosts"
                    ];
                in
                [ "sftp.args='${builtins.concatStringsSep " " sftpArgs}'" ];

            paths = [ "/var/lib/private/polyhelper" ];

            timerConfig = {
                OnCalendar = "daily";
                Persistent = true;
                RandomizedDelaySec = "10m";
            };

            # Keep all snapshots in the last week, and one every week for a month
            pruneOpts = [
                "--keep-daily 7"
                "--keep-weekly 4"
            ];
        };
}
