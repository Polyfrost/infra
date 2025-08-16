{
    pkgs,
    ips,
    config,
    ...
}:
{
    services.reposilite = {
        enable = true;

        database = {
            type = "postgresql";
            host = "[${ips.v6.containers.postgres}]";
            user = "reposilite";
            # This is necessary so reposilite doesn't complain about
            # the missing password, though if postgres doesn't require
            # a password then it still works
            passwordFile = pkgs.writeText "reposilite-db-password" "PLACEHOLDER";
        };

        plugins = with pkgs.reposilitePlugins; [ prometheus ];

        settings = {
            hostname = "0.0.0.0";
            port = 8080;
            sslEnabled = false;

            defaultFrontend = true;
            compressionStrategy = "gzip";
        };
    };

    systemd.services.reposilite.environment = {
        REPOSILITE_PROMETHEUS_USER = "prometheus";
        REPOSILITE_PROMETHEUS_PASSWORD = "prometheus";
    };

    # Backups
    systemd.services.restic-backups-reposilite.serviceConfig.LoadCredential = [
        "password:backups.passwords.restic.reposilite"
        "ssh_private_key:backups.sftp.private_key"
        "ssh_known_hosts:backups.sftp.known_hosts"
        "repository:restic.repository"
    ];
    services.restic.backups.reposilite =
        let
            credentialsDir = "/run/credentials/restic-backups-reposilite.service";
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

            paths = [ config.services.reposilite.workingDirectory ];

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
