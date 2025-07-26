{ inputs, self, ... }:
{
    imports = [
        # Enable lix (better fork of nix)
        inputs.lix-module.nixosModules.lixFromNixpkgs
        {
            nixpkgs.overlays = [
                # Provide the git lix package set in the location the module expects it to be
                (final: prev: {
                    lixPackageSets = prev.lixPackageSets // {
                        lix_2_94 = prev.lixPackageSets.git;
                    };
                })
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

        # Include configuration for testing via QEMU
        ./virtualization.nix

        # Include custom NixOS modules
        self.nixosModules.default

        ## Main configuration entrypoint
        ./config
    ];

    system.stateVersion = "25.05";
}
