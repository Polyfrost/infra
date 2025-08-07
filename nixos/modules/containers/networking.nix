{
    lib,
    config,
    customUtils,
    inputs,
    ...
}:
{
    options = {
        custom.nixos-containers.networking =
            let
                mkAddressesOption = version: {
                    cidr = lib.mkOption {
                        description = "The subnet IP${version} addresses are allocated from";
                        type = lib.types.str;
                    };
                    host = lib.mkOption {
                        description = "The IP${version} address assigned to the host";
                        type = lib.types.str;
                    };
                    gateway = lib.mkOption {
                        description = "The gateway IP${version} address for the bridge interface";
                        type = lib.types.str;
                    };
                    containers = lib.mkOption {
                        description = "An attrset of IP${version} addresses assigned per-container";
                        type = lib.types.attrsOf lib.types.str;
                    };
                };
            in
            {
                ipAllocations = lib.mkOption {
                    description = ''
                        A list of container IPs to allocate static IPs for. Containers are given IPs in the
                        same order of this list, so assign it all in one place to avoid confusion due to
                        module evaluation messing with the ordering.

                        This is used to ensure all containers are given a permanent IP static address, but
                        without having to assign them all individually.

                        The host will get the all-zeroes + 1 IP from the configured subnets, and the containers
                        will get all sequential IPs afterwards, in order (if the subnet is 10.2.4.0/24, then
                        the host will be assigned 10.2.4.1, and the first container will be assigned 10.2.4.2).

                        For IPv4, the gateway IP will be the all-ones IP - 1, and for IPv6 the gateway will be
                        the all-ones IP (due to lack of a broadcast address).
                    '';
                    default = [ ];
                    type = lib.types.listOf lib.types.str;
                };

                v4.cidr = lib.mkOption {
                    description = "The subnet to allocate IPs from, in CIDR notation";
                    type = lib.types.str;
                };

                v6 = {
                    ulaPrefix = lib.mkOption {
                        description = ''
                            The ULA (https://en.wikipedia.org/wiki/Unique_local_address) prefix to give containers
                            IPv6 addresses from. The specific subnet ID can be configured with the subnetId option.
                        '';
                        type = lib.types.str;
                    };

                    subnetId = lib.mkOption {
                        description = "The subnet ID to use from the provided ULA prefix";
                        default = 0;
                        type = lib.types.ints.u16;
                    };
                };

                addresses = {
                    v4 = mkAddressesOption "v4";
                    v6 = mkAddressesOption "v6";
                };
            };
    };

    config =
        let
            utils = customUtils;
            cfg = config.custom.nixos-containers.networking;

            genContainerIps =
                firstIp: nextIpFunc: renderIpFunc:
                (builtins.foldl'
                    (acc: i: {
                        nextIp = nextIpFunc acc.nextIp;
                        result = acc.result // {
                            "${builtins.elemAt cfg.ipAllocations i}" = renderIpFunc acc.nextIp;
                        };
                    })
                    {
                        nextIp = firstIp;
                        result = { };
                    }
                    (builtins.genList (i: i) (builtins.length cfg.ipAllocations))
                ).result;
        in
        {
            custom.nixos-containers.networking.addresses = {
                v4 =
                    let
                        parsed = utils.ipv4.parseCIDR cfg.v4.cidr;
                        masked = utils.ipv4.applyMask parsed.ip parsed.mask;
                        host = masked.first + 1;
                    in
                    {
                        inherit (cfg.v4) cidr;
                        host = utils.ipv4.toDottedDecimal host;
                        gateway = utils.ipv4.toDottedDecimal (masked.last - 1);

                        containers =
                            genContainerIps (host + 1) # First container IP
                                (ip: ip + 1) # Generates next IP
                                utils.ipv4.toDottedDecimal; # Converts IP to string
                    };

                v6 =
                    let
                        ipv6Lib = inputs.nixpkgs-ipv6-lib.lib.network.ipv6;
                        replaceIdx = idx: val: lib.imap0 (i: v: if (i == idx) then val else v);

                        parsedPrefix = ipv6Lib.fromString cfg.v6.ulaPrefix;
                        ulaSubnet = ipv6Lib.firstAddress (
                            parsedPrefix
                            // {
                                # Replace subnet ID in address (4th group)
                                _address = replaceIdx 3 cfg.v6.subnetId parsedPrefix._address;
                                # Adjust prefix size
                                prefixLength = 64;
                            }
                        );

                        host = ipv6Lib.nextAddress ulaSubnet;
                    in
                    {
                        cidr = ulaSubnet.addressCidr;
                        host = host.address;
                        gateway = (ipv6Lib.lastAddress ulaSubnet).address;

                        containers =
                            genContainerIps (ipv6Lib.nextAddress host) # First container IP
                                ipv6Lib.nextAddress # Generates next IP
                                (v: v.address); # Converts IP to string
                    };
            };
        };
}
