{
    sops = {
        defaultSopsFile = ./sops.yaml;
        defaultSopsFormat = "yaml";

        age.keyFile = "/var/lib/sops-nix/key.txt";
        age.generateKey = false;

        secrets = {
            "ursa/secret" = { };
            # Individual ursa/tokens/${name} secrets are in ./config/services/ursa/default.nix

            "plausible/smtp_password" = { };
            "plausible/secret_key_base" = { };

            "tailscale/oauth_key" = { };

            "users/ty/password_hash" = {
                neededForUsers = true;
            };
        };
    };

    # Ensure restrictive permissions on the keyfile
    systemd.tmpfiles.settings."10-sops-nix" = {
        "/var/lib/sops-nix"."d" = {
            user = "root";
            group = "root";
            mode = "700";
        };

        "/var/lib/sops-nix/key.txt"."f" = {
            user = "root";
            group = "root";
            mode = "600";
        };
    };
}
