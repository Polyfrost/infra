{ pkgs, lib, ... }:
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

    settings = {
        global.excludes = [ ".jj" ];
        formatter = {
            nixfmt.options = [
                "--indent"
                "4"
            ];
            caddy = {
                command = "${lib.getExe pkgs.bash}";
                options = [
                    "-euc"
                    ''
                        for file in "$@"; do
                            ${lib.getExe pkgs.caddy} fmt -w $file
                        done
                    ''
                    "--"
                ];
                includes = [
                    "*/[Cc]addyfile"
                    "*.[C]addyfile"
                ];
            };
        };
    };
}
