{ utils, inputs, ... }:
let
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
        "vector"
    ];

    # Configuration
    v4 = {
        # IPv4 has a few IP ranges marked as private, that can be
        # taken from and used arbitrarily. This CIDR notation will
        # just be taken from sequentially, with the first+1 and last-1
        # (where first means all zeroes and last means all ones) IPs
        # being used for the host and gateway addresses respectively.
        cidr = "172.25.0.0/24";
    };
    v6 = {
        # IPv6 has globally unique private ranges. The following
        # is a randomly generated globally unique prefix that /64
        # subnets can be taken from.
        #
        # This setup just uses only the first subnet (____:____:____:0::/64)
        # and assigns the first address to the host, the last address
        # as the gateway, and all others to the containers statically.
        ulaPrefix = "fd06:f707:1303::/48";
    };

    # Utils
    genContainerIps =
        firstIp: nextIpFunc: renderIpFunc:
        (builtins.foldl'
            (acc: i: {
                nextIp = nextIpFunc acc.nextIp;
                result = acc.result // {
                    "${builtins.elemAt ipAllocations i}" = renderIpFunc acc.nextIp;
                };
            })
            {
                nextIp = firstIp;
                result = { };
            }
            (builtins.genList (i: i) (builtins.length ipAllocations))
        ).result;
in
{
    v4 =
        let
            parsed = utils.ipv4.parseCIDR v4.cidr;
            masked = utils.ipv4.applyMask parsed.ip parsed.mask;
            host = masked.first + 1;
        in
        {
            inherit (v4) cidr;
            host = utils.ipv4.toDottedDecimal host;
            gateway = utils.ipv4.toDottedDecimal (masked.last - 1);

            # containers =
            #     (builtins.foldl'
            #         (acc: i: {
            #             nextIp = acc.nextIp + 1;
            #             result = acc.result // {
            #                 "${builtins.elemAt ipAllocations i}" = utils.ipv4.toDottedDecimal acc.nextIp;
            #             };
            #         })
            #         {
            #             nextIp = host + 1;
            #             result = { };
            #         }
            #         (builtins.genList (i: i) (builtins.length ipAllocations))
            #     ).result;
            containers =
                genContainerIps (host + 1) # First container IP
                    (ip: ip + 1) # Generates next IP
                    utils.ipv4.toDottedDecimal; # Converts IP to string
        };

    v6 =
        let
            ipv6Lib = inputs.nixpkgs-ipv6-lib.lib.network.ipv6;

            parsedPrefix = ipv6Lib.fromString v6.ulaPrefix;
            zeroedPrefix = ipv6Lib.firstAddress parsedPrefix;
            ulaSubnet = ipv6Lib.firstAddress (zeroedPrefix // { prefixLength = 64; });

            host = ipv6Lib.nextAddress ulaSubnet;
        in
        {
            cidr = ulaSubnet.addressCidr;
            host = host.address;
            gateway = (ipv6Lib.lastAddress ulaSubnet).address;

            containers =
                genContainerIps (ipv6Lib.nextAddress host) # First container IP
                    ipv6Lib.nextAddress # Generates next IP
                    ({ address, ... }: address); # Converts IP to string
        };
}
