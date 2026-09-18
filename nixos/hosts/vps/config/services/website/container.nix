{
    lib,
    pkgs,
    inputs,
    system,
    websiteInstance,
    ...
}:
let
    input = inputs.${websiteInstance.flakeInput};
    # nixpkgs `pnpm` is now pnpm_12 (Rust), whose override takes no `hash`;
    # the website's corepack-compat.nix needs the JS-based pnpm_10.
    website = input.packages.${system}.website.override {
        corepackCompat = pkgs.callPackage "${input}/nix/corepack-compat.nix" { pnpm = pkgs.pnpm_10; };
    };
in
{
    systemd.services.${websiteInstance.serviceName} = {
        wantedBy = [ "multi-user.target" ];

        environment = {
            HOST = "::";
            PORT = "8080";
        };

        serviceConfig = {
            ExecStart = lib.getExe website;

            EnvironmentFile = [ "/run/host/credentials/${websiteInstance.credential}" ];
        };
    };
}
