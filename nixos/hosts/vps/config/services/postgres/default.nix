args@{ pkgs, customUtils, ... }:
{
    containers.postgres = customUtils.mkContainer {
        name = "postgres";
        entrypoint = ./container.nix;
        ips = import ../ips.nix;
        inherit args;
    };
}
