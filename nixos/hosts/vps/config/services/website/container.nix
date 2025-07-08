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
            HOST = "0.0.0.0";
            PORT = "8080";
        };

        serviceConfig = {
            ExecStart = lib.getExe inputs.website.packages.${system}.website;
        };
    };
}
