{ inputs, ... }:
{
    nix = {
        # Set nixpkgs references in search path & flake registry lookup to system-wide nixpkgs
        nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
        registry.nixpkgs.to = {
            type = "path";
            path = builtins.toString inputs.nixpkgs;
        };

        settings = {
            # Enable modern nix command and flakes
            experimental-features = [
                "nix-command"
                "flakes"
            ];

            # Our binary caches. Without the matching public keys Nix fetches
            # the narinfo, fails signature verification and rebuilds from
            # source, so the two lists must always be updated together.
            extra-substituters = [
                "https://nix-community.cachix.org"
                "https://colmena.cachix.org"
                "https://polyfrost.cachix.org"
            ];
            extra-trusted-public-keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
                "polyfrost.cachix.org-1:fDpH46ULMhZsXOIu9JuiXBQUx1Z5cQsfOxXzd8Gvd20="
            ];

            # More parallel connections when pulling from the caches above.
            #
            # Note: this host runs Lix, not CppNix, so CppNix-only settings
            # (e.g. download-buffer-size) are rejected outright by the nix.conf
            # validation at build time.
            http-connections = 50;

            # Deliberately off: hard-linking every path as it is added makes
            # every `colmena apply` copy slower on this box. The weekly
            # nix.optimise timer below reclaims the same space off the deploy
            # path instead.
            auto-optimise-store = false;
        };

        # Automatically delete unused nix store paths.
        #
        # `gc.automatic` on its own runs bare `nix-collect-garbage`, which
        # deletes *everything* unreachable -- including the build inputs of the
        # current generation, so the next deploy re-fetches them. Keep a window.
        gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 30d";
        };

        # Hard-link duplicate store paths, but on a schedule rather than
        # synchronously during every deployment.
        optimise = {
            automatic = true;
            dates = [ "Sun 03:45" ];
        };
    };
}
