{ pkgs, config, ... }:
{
    # Make users fully declarative
    users.mutableUsers = false;

    # Set default shell to Zsh
    users.defaultUserShell = pkgs.zsh;
    users.users = {
        ty = {
            isNormalUser = true;
            useDefaultShell = true;
            description = "Tyler Beckman";
            extraGroups = [
                "wheel" # Can use sudo
            ];

            hashedPasswordFile = config.sops.secrets."users/ty/password_hash".path;
        };
    };

    # Enable polkit user authentication
    security.polkit.enable = true;
    security.pam.services.systemd-run0 = {
        setEnvironment = true;
        pamMount = false;
    }; # https://github.com/NixOS/nixpkgs/issues/361592#issuecomment-2516342739
}
