{ pkgs, lib, config, ... }:
{
    options = {
        services.ursa-minor = {
            enable = lib.mkEnableOption "ursa minor hypixel proxy";

            package = lib.mkPackageOption pkgs "ursa-minor" {};

            settings = {
                # TODO
            };
        };
    };

    config =
        let
            cfg = config.services.ursa-minor;
        in
        lib.mkIf (cfg.enable) {
            systemd.services.ursa-minor = {
                description = "Ursa minor hypixel proxy";

                wantedBy = [ "multi-user.target" ];

                serviceConfig = {
                    ExecStart = [ "${lib.getExe cfg.package} run-server" ];

                    Restart = "always";

                    DynamicUser = "yes";
                    PrivateTmp = true;
                    User = "ursa-minor-%i";
                    Group = "ursa-minor-%i";
                };
            };
        };
}
