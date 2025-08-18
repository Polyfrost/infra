{ config, ... }:
{
    custom.nixos-containers.containers.reposilite = {
        config = ./container.nix;

        dependencies = [ "container@postgres.service" ];

        secrets = [
            "backups/sftp/private_key"
            "backups/sftp/known_hosts"
            "backups/passwords/restic/reposilite"
            {
                sops = "backups/restic/repositories/reposilite";
                systemd = "restic.repository";
            }
        ];

        persistentDirs = {
            reposilite = "/var/lib/reposilite";
        };
    };

    sops.templates."backups/restic/repositories/reposilite".content = ''
        sftp:${config.sops.placeholder."backups/sftp/user"}@${
            config.sops.placeholder."backups/sftp/host"
        }:restic/reposilite
    '';
}
