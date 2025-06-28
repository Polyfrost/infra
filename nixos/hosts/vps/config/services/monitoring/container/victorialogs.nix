{
    # TODO `-retention.maxDiskSpaceUsageBytes=...` to add a hard disk space limit
    services.victorialogs = {
        enable = true;
        listenAddress = "0.0.0.0:8082";
    };
}
