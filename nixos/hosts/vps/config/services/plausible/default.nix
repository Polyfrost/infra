args@{ pkgs, customUtils, ... }:
{
    containers.plausible = customUtils.mkContainer {
        name = "plausible";
        entrypoint = ./container.nix;
        ips = import ../ips.nix;
        inherit args;

        secrets = {
            "plausible/smtp_password" = "plausible.smtp_password";
            "plausible/secret_key_base" = "plausible.secret_key_base";
        };
    };
}
