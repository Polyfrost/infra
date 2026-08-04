{
    lib,
    inputs,
    system,
    websiteInstance,
    ...
}:
{
    systemd.services.${websiteInstance.serviceName} = {
        wantedBy = [ "multi-user.target" ];

        environment = {
            HOST = "::";
            PORT = "8080";
        };

        serviceConfig = {
            ExecStart = lib.getExe inputs.${websiteInstance.flakeInput}.packages.${system}.website;

            EnvironmentFile = [ "/run/host/credentials/${websiteInstance.credential}" ];
        };
    };
}
