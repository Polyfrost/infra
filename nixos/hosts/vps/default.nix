{ inputs, self, ... }:
{
    imports = [
        # Enable lix (better fork of nix)
        inputs.lix-module.nixosModules.lixFromNixpkgs
        {
            nixpkgs.overlays = [
                # Override the top-level lix to be the nixpkgs version of 2.24.0-dev, which the module expects
                # Unfortunately the module is fairly out of date and can't find the latest lix on its own
                (final: prev: { lix = final.lixPackageSets.git.lix; })
            ];
        }

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

        # Include configuration for testing via QEMU
        ./virtualization.nix

        # Include custom NixOS modules
        self.nixosModules.default

        ## Main configuration entrypoint
        ./config
    ];

    system.stateVersion = "25.05";
}
