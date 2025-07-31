{
    lib,
    inputs,
    system,
    ips,
    ...
}:
{
    systemd.services.backend-v1 = {
        wantedBy = [ "multi-user.target" ];

        environment = {
            BACKEND_BIND_ADDRS = "[::]:8080";
            BACKEND_PUBLIC_MAVEN_URL = "https://repo.polyfrost.org";
            BACKEND_INTERNAL_MAVEN_URL = "http://[${ips.v6.containers.reposilite}]:8080";
        };

        serviceConfig.ExecStart = [ "${lib.getExe inputs.backend.packages.${system}.default}" ];
    };
}
