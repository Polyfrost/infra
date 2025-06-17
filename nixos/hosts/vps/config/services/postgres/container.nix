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
                    # TODO: limit connections more carefully in the case of an unpriveledged user takeover inside containers?
                    type = "host";
                    database = "sameuser";
                    user = name;
                    address = "${value}/32";
                    method = "trust";
                }) ips.containers
            )
        );
    };
}
