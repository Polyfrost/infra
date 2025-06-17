{ lib, ... }:
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
            power = lhs: rhs: builtins.foldl' (acc: _: acc * lhs) 1 (builtins.genList (_: null) rhs);
            shiftLeft = lhs: rhs: lhs * (utils.trivial.power 2 rhs);
            shiftRight = lhs: rhs: lhs / (utils.trivial.power 2 rhs);
        };

        ip = {
            parseCIDR =
                str:
                let
                    split = lib.splitString "/" str;
                in
                {
                    ip = utils.ip.parseIPv4 (builtins.elemAt split 0);
                    mask = utils.ip.getMask (lib.toIntBase10 (builtins.elemAt split 1));
                };

            parseIPv4 =
                ip:
                let
                    getPart = i: builtins.elemAt (builtins.split "\\." ip) (i * 2);
                    num = builtins.foldl' (
                        acc: cur:
                        builtins.bitOr acc (utils.trivial.shiftLeft (lib.toIntBase10 (getPart cur)) (8 * (3 - cur)))
                    ) 0 (builtins.genList (i: i) 4);
                in
                num;

            getMask = bits: utils.trivial.shiftLeft ((utils.trivial.power 2 bits) - 1) (32 - bits);

            applyMask =
                ip: mask:
                let
                    invertedMask = builtins.bitXor mask utils.consts.U32_MAX;
                in
                {
                    first = builtins.bitAnd ip mask;
                    last = builtins.bitOr ip invertedMask;
                };

            toDottedDecimal =
                num:
                let
                    parts = builtins.genList (
                        i: builtins.bitAnd utils.consts.U8_MAX (utils.trivial.shiftRight num ((3 - i) * 8))
                    ) 4;
                in
                builtins.concatStringsSep "." (builtins.map builtins.toString parts);
        };
    };
in
utils
