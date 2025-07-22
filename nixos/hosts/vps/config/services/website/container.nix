{
    lib,
    inputs,
    system,
    ...
}:
{
    systemd.services.polyfrost-website = {
        wantedBy = [ "multi-user.target" ];

        environment = {
            HOST = "::";
            PORT = "8080";
        };

        serviceConfig = {
            ExecStart = lib.getExe inputs.website.packages.${system}.website;

            EnvironmentFile = [ "/run/host/credentials/website.secrets.env" ];
        };
    };
}
