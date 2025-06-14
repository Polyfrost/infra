let
    modules = [
        ./containers.nix
        ./misc.nix
    ];
    utils = builtins.foldl' (
        acc: cur:
        let
            mod = import cur { };
            intersects = builtins.intersectAttrs acc mod;
            joined =
                if (intersects != { }) then
                    builtins.throw (
                        "Utils have duplicate function name(s) "
                        + (builtins.concatStringsSep ", " (builtins.attrNames intersects))
                    )
                else
                    acc // mod;
        in
        joined
    ) { } modules;
in
utils
