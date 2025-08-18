{
    boot = {
        loader = {
            grub = {
                enable = true;
                device = "nodev";
            };
        };

        initrd.systemd.enable = true;
    };
}
