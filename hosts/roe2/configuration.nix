{ config, pkgs, ... }:

{
  networking.hostId = "640c2c0b";
  networking.hostName = "roe2";

  boot.loader.grub.gfxmodeEfi = pkgs.lib.mkForce "2560x1440,auto";

  boot.kernelParams = [ "quiet" ];

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/9f3bdcd9-ff39-4b58-bed5-736600a5bab1";
      preLVM = true; 
    };
  };
}

