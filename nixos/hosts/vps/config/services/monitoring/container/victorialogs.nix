{
    services.victorialogs = {
        enable = true;
        listenAddress = ":8082";
        extraOptions = [
            "-enableTCP6"
            "-retentionPeriod=14d"
            "-retention.maxDiskSpaceUsageBytes=2GiB"
        ];
    };
}
