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

            # Automatically hard-link everything possible in the nix store
            auto-optimise-store = true;
        };
        # Automatically delete unused nix store paths
        gc.automatic = true;
    };
}
