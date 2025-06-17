{
    custom.containers.plausible = {
        entrypoint = ./container.nix;

        persistentDirs = {
            "plausible/clickhouse" = "/var/lib/clickhouse";
            "plausible/data" = "/var/lib/private/plausible";
        };

        secrets = [
            "plausible/smtp_password"
            "plausible/secret_key_base"
        ];

        dependencies = [ "container@postgres.service" ];
    };
}
