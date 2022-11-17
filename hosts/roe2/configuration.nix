{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  networking.hostId = "640c2c0b";
  networking.hostName = "roe2";

  boot.loader.grub.gfxmodeEfi = pkgs.lib.mkForce "2560x1440,auto";

  boot.kernelParams = [
    "quiet" "splash" "loglevel=2" "nowatchdog"

    # Only show plymouth on primary monitor
    "video=card0-DP-2:d" "video=card0-DP-2:d"
  ];

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/9f3bdcd9-ff39-4b58-bed5-736600a5bab1";
      preLVM = true; 
    };
  };
}

