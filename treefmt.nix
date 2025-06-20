{
    projectRootFile = "flake.nix";

    programs = {
        nixfmt = {
            enable = true;
            strict = true;
            width = 100;
        };
        just.enable = true;
        mdformat = {
            enable = true;
            settings = {
                end-of-line = "lf";
                number = false;
                wrap = 100;
            };
        };
    };

    settings.formatter.nixfmt.options = [
        "--indent"
        "4"
    ];
}
