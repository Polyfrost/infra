{ ... }:
{
    mkPostgresAuthentication =
        rules:
        builtins.concatStringsSep "\n" (
            builtins.map (
                {
                    type,
                    database,
                    user,
                    address ? "",
                    method,
                }:
                "${type} ${database} ${user} ${address} ${method}"
            ) rules
        );
}
