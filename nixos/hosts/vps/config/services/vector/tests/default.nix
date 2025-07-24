{ lib, ... }:
{
    services.vector.settings = {
        tests = [
            {
                name = "Test caddy access log processing";

                inputs =
                    let
                        logs = builtins.map builtins.fromJSON (
                            lib.splitString "\n" (lib.trim (builtins.readFile ./caddy_access.jsonl))
                        );
                    in
                    builtins.map (log: {
                        type = "log";
                        insert_at = "process_caddy_access";
                        log_fields = log;
                    }) logs;

                outputs = [
                    {
                        extract_from = "process_caddy_access";
                        conditions = [
                            {
                                type = "vrl";
                                source = builtins.readFile ./caddy_access.vrl;
                            }
                        ];
                    }
                ];
            }
        ];
    };
}
