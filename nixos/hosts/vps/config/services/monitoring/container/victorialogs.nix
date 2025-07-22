{
    # TODO `-retention.maxDiskSpaceUsageBytes=...` to add a hard disk space limit
    services.victorialogs = {
        enable = true;
        listenAddress = ":8082";
        extraOptions = [ "-enableTCP6" ];
    };
}
