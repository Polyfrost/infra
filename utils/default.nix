args@{ lib, ... }:
let
    utils = {
        consts = {
            U8_MAX = 255;
            U32_MAX = 4294967295;
        };

        mkPostgresAuthentication =
            rules:
            builtins.concatStringsSep "\n" (
                builtins.map (
                    {
                        type,
                        database,
                        user,
                        address ? "",
                        method,
                    }:
                    "${type} ${database} ${user} ${address} ${method}"
                ) rules
            );

        trivial = {
            pow = lhs: rhs: builtins.foldl' (acc: _: acc * lhs) 1 (builtins.genList (_: null) rhs);
            # Both of the following only expect positive numbers
            shl = lhs: rhs: lhs * (utils.trivial.pow 2 rhs);
            shr = lhs: rhs: lhs / (utils.trivial.pow 2 rhs);
        };

        ipv4 = import ./ipv4.nix (args // { inherit utils; });
    };
in
utils
