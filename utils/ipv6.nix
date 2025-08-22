{ lib, ... }:
{
    # Takes a non-compressed IPv6 address string and compresses the first sequence of 0s
    compressAddr =
        addr:
        let
            splitAddr = lib.splitString ":" addr;
            compressed =
                builtins.foldl'
                    (
                        {
                            hasCompressed,
                            isCompressing,
                            result,
                        }:
                        { i, v }:
                        if (!isCompressing) then
                            if (!hasCompressed && v == "0" && (builtins.elemAt splitAddr (i + 1)) == "0") then
                                {
                                    isCompressing = true;
                                    hasCompressed = true;
                                    result = result ++ [ "" ];
                                }
                            else
                                {
                                    inherit isCompressing hasCompressed;
                                    result = result ++ [ v ];
                                }
                        else if (v == "0") then
                            { inherit hasCompressed isCompressing result; }
                        else
                            {
                                inherit hasCompressed;
                                isCompressing = false;
                                result = result ++ [ v ];
                            }
                    )
                    {
                        hasCompressed = false;
                        isCompressing = false;
                        result = [ ];
                    }
                    (
                        builtins.genList (i: {
                            inherit i;
                            v = builtins.elemAt splitAddr i;
                        }) (builtins.length splitAddr)
                    );
        in
        builtins.concatStringsSep ":" compressed.result;
}
