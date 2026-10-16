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
        # common-lix.nix passes `-Dmimalloc=` unconditionally, but the option
        # only exists from Lix 2.96 on, so 2.95 (stable) fails at meson configure.
        # TODO: Remove once nixpkgs gates the flag on the Lix version.
        (_: prev: {
            lixPackageSets = prev.lixPackageSets.extend (
                _: lprev: {
                    stable = lprev.stable.overrideScope (
                        _: sprev: {
                            lix = sprev.lix.overrideAttrs (old: {
                                mesonFlags = prev.lib.remove "-Dmimalloc=disabled" old.mesonFlags;
                            });
                        }
                    );
                }
            );
        })

        (final: prev: {
            inherit (prev.lixPackageSets.stable)
                nixpkgs-review
                # nix-eval-jobs
                nix-fast-build
                colmena
                ;
        })

        # URI 5.36 ships URI::ws itself, which collides with the separate
        # URI-ws distribution that CatalystRuntime propagates, breaking hydra's
        # `perlDeps` buildEnv. Drop the now-redundant standalone package.
        # TODO: Remove once nixpkgs stops referencing perlPackages.URIws.
        (_: prev: {
            perlPackages = prev.perlPackages.overrideScope (_: pprev: { URIws = pprev.URI; });
        })
    ];
    nix.package = pkgs.lixPackageSets.stable.lix;
}
