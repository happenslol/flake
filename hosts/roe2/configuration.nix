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
    # Quiet boot (See https://wiki.archlinux.org/title/silent_boot)
    "quiet" "splash" "loglevel=3" "nowatchdog"
    "systemd.show_status=auto" "rd.udev.log_level=3"
  ];

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/9f3bdcd9-ff39-4b58-bed5-736600a5bab1";
      preLVM = true; 
    };
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
