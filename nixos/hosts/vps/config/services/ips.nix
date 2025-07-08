{ utils, ... }:
let
    # Configuration
    cidr = "172.25.0.0/24";
    ipAllocations = [
        # All new allocations should go to the end.If any indexes change, the container IPs will also change.
        "caddy"
        "postgres"
        "reposilite"
        "backend-legacy"
        "backend"
        "ursa-minor-hytils"
        "ursa-minor-dsm"
        "ursa-minor-pss"
        "monitoring"
        "website"
    ];

    parsed = utils.ip.parseCIDR cidr;
    masked = utils.ip.applyMask parsed.ip parsed.mask;
    host = masked.first + 1;
in
{
    inherit cidr;
    host = utils.ip.toDottedDecimal host;
    gateway = utils.ip.toDottedDecimal (masked.last);

    containers =
        (builtins.foldl'
            (acc: i: {
                nextIp = acc.nextIp + 1;
                result = acc.result // {
                    "${builtins.elemAt ipAllocations i}" = utils.ip.toDottedDecimal acc.nextIp;
                };
            })
            {
                nextIp = host + 1;
                result = { };
            }
            (builtins.genList (i: i) (builtins.length ipAllocations))
        ).result;
}
