{
    pkgs,
    inputs,
    system,
    config,
    ...
}:
{
    # Install system packages
    environment.systemPackages = with pkgs; [
        # Basic necessities
        wget
        curl
        neovim
        inputs.nixos-facter.packages.${system}.nixos-facter
        git
    ];

    # Install zsh
    programs.zsh.enable = true;

    # Disable default command-not-found (it doesn't work with flakes)
    programs.command-not-found.enable = false;

    # Run node exporter on the host for metrics
    services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        listenAddress = config.custom.containerIps.host;
    };
}
