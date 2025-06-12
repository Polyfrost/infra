{
    projectRootFile = "flake.nix";

    programs = {
        nixfmt = {
            enable = true;
            strict = true;
        };
        just.enable = true;
    };

    settings.formatter.nixfmt.options = [
        "--indent"
        "4"
    ];
}
