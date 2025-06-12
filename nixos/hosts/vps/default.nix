{ inputs, ... }:
{
    imports = [
        # Enable lix (better fork of nix)
        inputs.lix-module.nixosModules.lixFromNixpkgs

        # Secrets provisioning
        inputs.sops-nix.nixosModules.sops
        ./secrets.nix

        # Disk formatting & mounting
        inputs.disko.nixosModules.disko
        ./disk-configuration.nix

        # Hardware configuration
        inputs.nixos-facter-modules.nixosModules.facter
        { facter.reportPath = ./facter.json; }

        # Enable home manager
        inputs.home-manager.nixosModules.home-manager
        # TODO add ty home-manager configuration as input and such

        ## Main configuration entrypoint
        ./config
    ];

    system.stateVersion = "25.05";
}
