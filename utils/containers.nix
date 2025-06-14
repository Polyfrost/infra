{ ... }:
{
    mkContainer =
        {
            name,
            entrypoint,
            ips,
            args,
            # A map of sops-nix secret name -> systemd credential name (in container)
            secrets ? { },
        }:
        {
            config = {
                imports = [ entrypoint ];

                system.stateVersion = "25.05";
                nixpkgs.pkgs = args.pkgs;

                nix.settings.experimental-features = [
                    "nix-command"
                    "flakes"
                ];

                services.oidentd.enable = true;

                networking.firewall.enable = false;
                networking.useHostResolvConf = false;
                services.resolved.enable = true;
            };

            autoStart = true;
            privateNetwork = true;
            ephemeral = true;
            hostBridge = "br0";
            localAddress = "${ips.${name}}/24";
            hostAddress = ips.host;

            specialArgs = {
                inherit ips;
                inherit (args) customUtils;
            };

            extraFlags = args.lib.mapAttrsToList (
                name: value: "--load-credential=${value}:${args.config.sops.secrets.${name}.path}"
            ) secrets;
        };
}
