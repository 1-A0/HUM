# /hosts/modules/disk-config.nix
# Declarative disk layout using Btrfs with a subvolume scheme and a swap file.

{ ... }:

{
  disko.devices = {
    disk = {
      # The target disk for installation.
      nvme0 = {
        type = "disk";
        device = "/dev/nvme0n1"; # This is the device you specified.
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00"; # ESP partition type
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                # Create the subvolumes within the Btrfs filesystem
                subvolumes = {
                  "/@" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/@home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/@nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/@vms" = { mountpoint = "/vms"; mountOptions = [ "nodatacow" ]; };
                  "/@log" = { mountpoint = "/var/log"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/@swap" = { mountpoint = "/swap"; mountOptions = [ "nodatacow" ]; };
                };
              };
            };
          };
        };
      };
    };
    # This section declaratively creates the 16GB swap file.
    swap = {
      swap = {
        type = "swap";
        path = "/swap/swapfile";
        size = "16G";
      };
    };
  };
}

