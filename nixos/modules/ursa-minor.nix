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
            users = {
                users.ursa-minor = {
                    isSystemUser = true;
                    group = "ursa-minor";
                };
                groups.ursa-minor = { };
            };

            services.redis.servers.ursa-minor = {
                enable = true;
                user = "ursa-minor";
            };

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

                    User = "ursa-minor";
                    Group = "ursa-minor";

                    Restart = "always";
                    TimeoutStopSec = 5; # Ursa currently doesn't handle SIGTERM properly, so don't wait around for it to stop

                    # Systemd Hardening
                    RemoveIPC = true;
                    PrivateTmp = true;
                    RestricSUIDSGID = true;
                    ProtectSystem = "strict";
                    ProtectHome = true;
                    PrivateDevices = true;
                    ProtectClock = true;
                    ProtectKernelLogs = true;
                    ProtectControlGroups = true;
                    ProtectKernelModules = true;
                    SystemCallArchitectures = "native";
                    MemoryDenyWriteExecute = true;
                    ProtectHostname = true;
                    LockPersonality = true;
                    ProtectKernelTunables = true;
                    RestrictRealtime = true;
                    ProtectProc = true;
                    PrivateUsers = true;
                    NoNewPrivileges = true;

                    # Only allowlist IPv4 & IPv6 sockets
                    RestrictAddressFamilies = [
                        "AF_INET"
                        "AF_INET6"
                        "AF_UNIX"
                    ];

                    RestrictNamespaces = [
                        "~user" # Service may create user namespaces
                        "~pid" # Service may create process namespaces
                        "~net" # Service may create network namespaces
                        "~uts" # Service may create hostname namespaces
                        "~mnt" # Service may create file system namespaces
                        "~cgroup" # Service may create cgroup namespaces
                        "~ipc" # Service may create IPC namespaces
                    ];

                    CapabilityBoundingSet = [
                        "~CAP_SYS_TIME" # Service processes may change the system clock
                        "~CAP_SYS_PACCT" # Service may use acct()
                        "~CAP_KILL" # Service may send UNIX signals to arbitrary processes
                        "~CAP_WAKE_ALARM" # Service may program timers that wake up the system
                        "~CAP_LINUX_IMMUTABLE" # Service may mark files immutable
                        "~CAP_IPC_LOCK" # Service may lock memory into RAM
                        "~CAP_SYS_MODULE" # Service may load kernel modules
                        "~CAP_BPF" # Service may load BPF programs
                        "~CAP_SYS_TTY_CONFIG" # Service may issue vhangup()
                        "~CAP_SYS_BOOT" # Service may issue reboot()
                        "~CAP_SYS_CHROOT" # Service may issue chroot()
                        "~CAP_BLOCK_SUSPEND" # Service may establish wake locks
                        "~CAP_LEASE" # Service may create file leases
                        "~CAP_MKNOD" # Service may create device nodes
                        "~CAP_SYS_RAWIO" # Service has raw I/O access
                        "~CAP_SYS_PTRACE" # Service has ptrace() debugging abilities
                        "~CAP_NET_ADMIN" # Service has network configuration privileges
                        "~CAP_SYS_ADMIN" # Service has administrator privileges
                        "~CAP_SYSLOG" # Service has access to kernel logging

                        # Service has audit subsystem access
                        "~CAP_SYS_AUDIT_CONTROL"
                        "~CAP_SYS_AUDIT_READ"
                        "~CAP_SYS_AUDIT_WRITE"

                        # Service has elevated networking privileges
                        "~CAP_NET_BIND_SERVICE"
                        "~CAP_NET_BROADCAST"
                        "~CAP_NET_RAW"

                        # Service has privileges to change resource use parameters
                        "~CAP_SYS_NICE"
                        "~CAP_SYS_RESOURCE"

                        # Service may adjust SMACK MAC
                        "~CAP_MAC_ADMIN"
                        "~CAP_MAC_OVERRIDE"

                        # Service may change file ownership/access mode/capabilities unrestricted
                        "~CAP_CHOWN"
                        "~CAP_FSETID"
                        "~CAP_SETFCAP"

                        # Service may change UID/GID identities/capabilities
                        "~CAP_SETUID"
                        "~CAP_SETGID"
                        "~CAP_SETPCAP"

                        # Service may override UNIX file/IPC permission checks
                        "~CAP_DAC_OVERRIDE"
                        "~CAP_DAC_READ_SEARCH"
                        "~CAP_FOWNER"
                        "~CAP_IPC_OWNER"
                    ];

                    SystemCallFilter = [
                        "~@clock"
                        "~@cpu-emulation"
                        "~@module"
                        "~@mount"
                        "~@obsolete"
                        "~@privileged"
                        "~@raw-io"
                        "~@reboot"
                        "~@swap"
                    ];
                };
            };
        };
}
