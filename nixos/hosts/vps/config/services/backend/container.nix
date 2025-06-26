{
    lib,
    inputs,
    system,
    ips,
    ...
}:
{
    systemd.services = {
        backend-legacy = {
            wantedBy = [ "multi-user.target" ];

            environment = {
                PORT = "8080";
                PUBLIC_MAVEN_URL = "https://repo.polyfrost.org";
                INTERNAL_MAVEN_URL = "http://${ips.containers.reposilite}:8080";
            };

            serviceConfig.ExecStart = [ "${lib.getExe inputs.backend-legacy.packages.${system}.default}" ];
        };
        backend-v1 = {
            wantedBy = [ "multi-user.target" ];

            environment = {
                BACKEND_LISTEN_HOST = "0.0.0.0";
                BACKEND_LISTEN_PORT = "8081";
                BACKEND_PUBLIC_MAVEN_URL = "https://repo.polyfrost.org";
                BACKEND_INTERNAL_MAVEN_URL = "http://${ips.containers.reposilite}:8080";
            };

            serviceConfig.ExecStart = [ "${lib.getExe inputs.backend-v1.packages.${system}.default}" ];
        };
    };
}
