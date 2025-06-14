{
    lib,
    ips,
    customUtils,
    ...
}:
{
    services.postgresql = {
        enable = true;
        enableJIT = true;
        enableTCPIP = true;

        ensureDatabases = [ "plausible" ];

        ensureUsers = [
            {
                name = "plausible";
                ensureDBOwnership = true;
            }
        ];

        authentication = lib.mkForce (
            customUtils.mkPostgresAuthentication (
                [
                    {
                        # Use peer authentication for local connections
                        type = "local";
                        database = "all";
                        user = "all";
                        method = "peer";
                    }
                ]
                ++ lib.mapAttrsToList (name: value: {
                    # Trust TCP connections from containers to a database & user
                    # with their name, without password authentication
                    #
                    # Postgres will use the container's ident server to check
                    # usernames, protecting against an unpriveledged non-service
                    # user in the container connecting to the database
                    type = "host";
                    database = "sameuser";
                    user = name;
                    address = "${value}/32";
                    method = "ident";
                }) ips
            )
        );
    };
}
