{...}: {
  disko.devices = {
    disk.root = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["nofail"];
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };
    zpool.rpool = {
      type = "zpool";
      options.ashift = "12";

      rootFsOptions = {
        mountpoint = "none";
        compression = "lz4";
        atime = "off";
        xattr = "sa";
        acltype = "posixacl";

        encryption = "on";
        keyformat = "passphrase";
        keylocation = "prompt";
      };

      datasets = {
        "root" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "/";
        };

        "reserved" = {
          type = "zfs_fs";
          mountpoint = "none";
          options.refreservation = "50G";
        };

        "nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "/nix";
        };

        "var" = {
          type = "zfs_fs";
          mountpoint = "/var";
          options.mountpoint = "/var";
        };

        "home" = {
          type = "zfs_fs";
          mountpoint = "/home";
          options.mountpoint = "/home";
        };
      };
    };
  };
}
