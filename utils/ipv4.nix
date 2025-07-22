{ lib, utils, ... }:
let
    ipv4 = {
        parseCIDR =
            str:
            let
                split = lib.splitString "/" str;
            in
            {
                ip = ipv4.parseIPv4 (builtins.elemAt split 0);
                mask = ipv4.getMask (lib.toIntBase10 (builtins.elemAt split 1));
            };

        parseIPv4 =
            ip:
            let
                getPart = i: builtins.elemAt (builtins.split "\\." ip) (i * 2);
                num = builtins.foldl' (
                    acc: cur: builtins.bitOr acc (utils.trivial.shl (lib.toIntBase10 (getPart cur)) (8 * (3 - cur)))
                ) 0 (builtins.genList (i: i) 4);
            in
            num;

        getMask = bits: utils.trivial.shl ((utils.trivial.pow 2 bits) - 1) (32 - bits);

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
                    i: builtins.bitAnd utils.consts.U8_MAX (utils.trivial.shr num ((3 - i) * 8))
                ) 4;
            in
            builtins.concatStringsSep "." (builtins.map builtins.toString parts);
    };
in
ipv4
