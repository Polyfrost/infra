{
    inputs,
    self,
    pkgs,
    ...
}:
{
    imports = [
        # Secrets provisioning
        inputs.sops-nix.nixosModules.sops
        ./secrets.nix

        # Disk formatting & mounting
        inputs.disko.nixosModules.disko
        ./disk-configuration.nix

        # Hardware configuration
        inputs.nixos-facter-modules.nixosModules.facter
        { facter.reportPath = ./facter.json; }

        # Nix index & comma setup
        inputs.nix-index-database.nixosModules.nix-index
        { programs.nix-index-database.comma.enable = true; }

        # Include configuration for testing via QEMU
        ./virtualization.nix

        # Include custom NixOS modules
        self.nixosModules.default

        ## Main configuration entrypoint
        ./config
    ];

    system.stateVersion = "25.05";

    # Enable lix (better fork of nix)
    nixpkgs.overlays = [
        (final: prev: {
            inherit (prev.lixPackageSets.stable)
                nixpkgs-review
                # nix-eval-jobs
                nix-fast-build
                colmena
                ;
        })
    ];
    nix.package = pkgs.lixPackageSets.stable.lix;
}
