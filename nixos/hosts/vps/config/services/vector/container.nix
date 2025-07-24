{
    ips,
    hostConfig,
    lib,
    ...
}:
{
    # Tests can be run via <flake>.checks.<system>.vector
    imports = [ ./tests ];

    # Automatically download and update GeoIP databases
    systemd.services.geoipupdate.serviceConfig.LoadCredential = [
        "maxmind_license_key:vector.maxmind_license_key"
        "maxmind_account_id:vector.maxmind_account_id"
    ];
    services.geoipupdate = {
        enable = true;
        settings = {
            # The module doesn't support use of secrets in AccountID,
            # so use this hacky workaround
            #
            # The account ID is in a secret because it is used by a script
            # in the Justfile
            AccountID =
                let
                    matched = builtins.match ''.+maxmind_account_id_unencrypted:[[:space:]]*"([[:digit:]]+)".+'' (
                        builtins.readFile hostConfig.sops.defaultSopsFile
                    );
                    id = lib.toIntBase10 (builtins.elemAt matched 0);
                in
                id;
            LicenseKey = {
                _secret = "/run/credentials/geoipupdate.service/maxmind_license_key";
            };
            EditionIDs = [
                "GeoLite2-ASN"
                "GeoLite2-City"
                "GeoLite2-Country"
            ];
            DatabaseDirectory = "/var/lib/geoip";
        };
    };
    systemd.tmpfiles.settings."10-geoip-db" = {
        "/var/lib/geoip"."z" = {
            mode = "0755";
        };
        "/var/lib/geoip/*.mmdb"."z" = {
            mode = "0644";
        };
    };

    services.vector = {
        enable = true;
        journaldAccess = false; # VictoriaLogs manages journald

        settings = {
            schema.log_namespace = true;

            enrichment_tables = {
                geolite2_city = {
                    path = "/var/lib/geoip/GeoLite2-City.mmdb";
                    type = "geoip";
                };
            };

            sources = {
                intake_caddy_net = {
                    type = "socket";
                    mode = "tcp";
                    address = "[::]:9000";
                    permit_origin = [
                        "${ips.v4.containers.caddy}/32"
                        "${ips.v6.containers.caddy}/128"
                    ];

                    decoding.codec = "json";
                    framing.method = "newline_delimited";
                };
            };

            transforms = {
                # Process all caddy access logs
                process_caddy_access = {
                    type = "remap";
                    inputs = [ "intake_caddy_net" ];

                    file = ./transforms/process_caddy_access.vrl;
                };
            };

            sinks = {
                victorialogs = {
                    inputs = [ "process_caddy_access" ];
                    type = "http";
                    uri = "http://[${ips.v6.containers.monitoring}]:8082/insert/jsonline";
                    encoding.codec = "json";
                    framing.method = "newline_delimited";
                    request.headers = {
                        "VL-Msg-Field" = "msg";
                        "VL-Time-Field" = "ts";
                        "VL-Stream-Fields" = "_LOG_SOURCE,logger";
                        "VL-Extra-Fields" = "_LOG_SOURCE=caddy";
                    };
                };
            };
        };
    };
}
