{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  services.sanoid = {
    enable = true;
    datasets."rpool/user" = {
      recursive = true;
      monthly = 1;
      daily = 10;
      autosnap = true;
      autoprune = true;
      processChildrenOnly = true;
    };
  };
}
