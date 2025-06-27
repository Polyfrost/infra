{
    pkgs,
    lib,
    config,
    ...
}:
{
    options = {
        services.ursa-minor = {
            enable = lib.mkEnableOption "ursa minor hypixel proxy";

            package = lib.mkPackageOption pkgs "ursa-minor" { };

            settings = {
                address = lib.mkOption {
                    description = "The address for the service to bind to";
                    default = "172.0.0.1";
                    type = lib.types.str;
                };

                port = lib.mkOption {
                    description = "The port for the service to bind to";
                    default = 8080;
                    type = lib.types.port;
                };

                rules = lib.mkOption {
                    description = "A list of rule files to pass to ursa minor, controlling which hypixel endpoints are availible";
                    default = [ ];
                    type = lib.types.listOf lib.types.path;
                };

                allowAnonymous = lib.mkOption {
                    description = "Whether or not to allow anonymous access (use of the API without mojang authentication)";
                    default = false;
                    type = lib.types.bool;
                };

                tokenLifespan = lib.mkOption {
                    description = "How long authentication tokens should remain valid for (in seconds)";
                    default = 3600;
                    type = lib.types.int;
                };

                rateLimitTimeout = lib.mkOption {
                    description = "How long a rate limit bucket lasts before being reset, i.e. how long users must wait before their request quota is reset";
                    default = 300;
                    type = lib.types.int;
                };

                rateLimitBucket = lib.mkOption {
                    description = "How many requests a rate limit bucket contains, i.e. how many requests can be made in a single 'rateLimitTimeout' period";
                    default = 5;
                    type = lib.types.int;
                };

                environmentFile = lib.mkOption {
                    description = "A file path to load as environment variables for the ursa minor process. This should include URSA_SECRET and URSA_HYPIXEL_TOKEN as secrets.";
                    default = null;
                    type = lib.types.path;
                };
            };
        };
    };

    config =
        let
            cfg = config.services.ursa-minor;
        in
        lib.mkIf (cfg.enable) {
            services.redis.servers.ursa-minor = {
                enable = true;
                user = "ursa-minor";
            };

            # Fix for using redis w/ a DynamicUser service
            systemd.services.redis-ursa-minor.serviceConfig.DynamicUser = "yes";

            systemd.services.ursa-minor = {
                description = "Ursa minor hypixel proxy";

                requires = [ "redis-ursa-minor.service" ];
                wantedBy = [ "multi-user.target" ];

                environment = {
                    URSA_REDIS_URL = "redis+unix://${config.services.redis.servers.ursa-minor.unixSocket}";
                    URSA_ADDRESS = cfg.settings.address;
                    URSA_PORT = builtins.toString cfg.settings.port;
                    URSA_RULES = builtins.concatStringsSep ":" cfg.settings.rules;
                    URSA_ANONYMOUS = if cfg.settings.allowAnonymous then "true" else "false";
                    URSA_TOKEN_LIFESPAN = builtins.toString cfg.settings.tokenLifespan;
                    URSA_RATE_LIMIT_TIMEOUT = builtins.toString cfg.settings.rateLimitTimeout;
                    URSA_RATE_LIMIT_BUCKET = builtins.toString cfg.settings.rateLimitBucket;
                };

                serviceConfig = {
                    ExecStart = [ "${lib.getExe cfg.package} run-server" ];
                    EnvironmentFile = [ cfg.settings.environmentFile ];

                    Restart = "always";

                    DynamicUser = "yes";
                    PrivateTmp = true;
                    User = "ursa-minor";
                    Group = "ursa-minor";

                    TimeoutStopSec = 5; # Ursa currently doesn't handle SIGTERM properly, so don't wait around for it to stop
                };
            };
        };
}
