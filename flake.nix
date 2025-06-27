{
    description = "Polyfrost Infrastructure";

    inputs = {
        # Nixpkgs
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
        # Flake utils
        flake-utils.url = "github:numtide/flake-utils";
        # Treefmt
        treefmt-nix = {
            url = "github:numtide/treefmt-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # Lix
        lix-module = {
            url = "git+https://git.lix.systems/lix-project/nixos-module";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # Facter (for hardware configuration)
        nixos-facter = {
            url = "github:nix-community/nixos-facter";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
        # Colmena unstable
        colmena = {
            url = "github:zhaofengli/colmena";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # Sops-nix
        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # Disko
        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # Home Manager + Plasma
        home-manager = {
            url = "github:nix-community/home-manager/master";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        # Nixos-anywhere & nixos-images for deployment
        nixos-anywhere = {
            url = "github:nix-community/nixos-anywhere";
            inputs = {
                nixpkgs.follows = "nixpkgs";
                nixos-stable.follows = "nixpkgs-stable";
                disko.follows = "disko";
            };
        };
        nixos-images = {
            url = "github:nix-community/nixos-images";
            # Nixpkgs inputs deliberately not ignored to avoid rebuilds and use the cache instead
        };
        # External services run on our infra
        backend-legacy = {
            url = "github:Polyfrost/backend/main";
            inputs = {
                nixpkgs.follows = "nixpkgs";
                flake-utils.follows = "flake-utils";
            };
        };
        backend-v1 = {
            url = "github:Polyfrost/backend/v1";
            inputs = {
                nixpkgs.follows = "nixpkgs";
                flake-utils.follows = "flake-utils";
            };
        };
        ursa-minor = {
            # url = "github:NotEnoughUpdates/ursa-minor";
            url = "github:Polyfrost/ursa-minor"; # Fork w/ prometheus metrics support
            inputs = {
                # Nixpkgs override breaks as the rust-overlay input then is desynced and
                # it tries to execute scripts that don't exist during build
                flake-utils.follows = "flake-utils";
            };
        };
    };

    outputs =
        inputs@{
            self,
            nixpkgs,
            colmena,
            flake-utils,
            nixos-anywhere,
            treefmt-nix,
            disko,
            ...
        }:
        let
            mkPkgs = system: import nixpkgs { inherit system; };
        in
        {
            nixosConfigurations = {
                "vps" = nixpkgs.lib.nixosSystem (
                    let
                        system = "x86_64-linux";
                    in
                    {
                        system = "x86_64-linux";
                        pkgs = mkPkgs system;
                        specialArgs = {
                            inherit inputs system self;
                            customUtils = import ./utils { inherit (nixpkgs) lib; };
                        };

                        modules = [ ./nixos/hosts/vps ];
                    }
                );
            };

            colmenaHive = colmena.lib.makeHive {
                meta = {
                    nixpkgs = mkPkgs "x86_64-linux";
                    specialArgs = {
                        inherit inputs self;
                        customUtils = import ./utils { inherit (nixpkgs) lib; };
                    };

                    nodeNixpkgs = {
                        vps = mkPkgs "x86_64-linux";
                    };
                    nodeSpecialArgs = {
                        vps = {
                            system = "x86_64-linux";
                        };
                    };
                };

                vps = {
                    deployment = {
                        targetHost = "polyfrost-vps";
                        targetUser = "root";
                        targetPort = 22;
                    };

                    imports = [ ./nixos/hosts/vps ];
                };
            };

            nixosModules.default = import ./nixos/modules;
        }
        // (flake-utils.lib.eachDefaultSystem (
            system:
            let
                pkgs = mkPkgs system;
                treefmt = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
                treefmt-wrapper = treefmt.config.build.wrapper;
            in
            {
                devShells.default = pkgs.mkShellNoCC {
                    packages =
                        [
                            nixos-anywhere.packages.${system}.default
                            colmena.packages.${system}.colmena
                            treefmt-wrapper
                        ]
                        ++ (with pkgs; [
                            just
                            age
                            sops
                        ]);
                };

                formatter = treefmt-wrapper;
                checks.formatting = treefmt.config.build.check self;

                # Re-export a kexec image locked on the flake's version of nixos-images
                packages.kexec-image =
                    inputs.nixos-images.packages.${system}.kexec-installer-nixos-stable-noninteractive;
            }
        ));

    nixConfig = {
        extra-substituters = [
            "https://nix-community.cachix.org"
            "https://colmena.cachix.org"
        ];
        extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
        ];
    };
}
