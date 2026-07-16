{
    lib,
    inputs,
    system,
    plusWebsiteInstance,
    ...
}:
{
    systemd.services.${plusWebsiteInstance.name} = {
        wantedBy = [ "multi-user.target" ];

        environment = {
            # next's standalone server reads HOSTNAME, not HOST
            HOSTNAME = "::";
            PORT = "8080";
        };

        serviceConfig = {
            # BACKEND_URL is inlined into the client bundle at build time, so it
            # is set here rather than in `environment` above. For production this
            # matches the package's default, so it stays a cache hit
            ExecStart = lib.getExe (
                inputs.${plusWebsiteInstance.flakeInput}.packages.${system}.plus-website.override {
                    inherit (plusWebsiteInstance) backendUrl;
                }
            );

            DynamicUser = true;

            Restart = "on-failure";
            RestartSec = "5s";
        };
    };
}
