{
    services.reposilite = {
        enable = true;
        database = {
            # Unfortunately the NixOS module does not allow for an external postgres database
            # without authentication, so for now just use sqlite
            type = "sqlite";
        };
        settings = {
            hostname = "0.0.0.0";
            port = 8080;
            sslEnabled = false;

            defaultFrontend = true;
            compressionStrategy = "gzip";
        };
    };
}
