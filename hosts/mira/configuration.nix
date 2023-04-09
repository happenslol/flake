{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.nixos-hardware.nixosModules.framework-12th-gen-intel];

  networking.hostId = "3ef514cd";
  networking.hostName = "mira";

  boot.loader.grub.gfxmodeEfi = pkgs.lib.mkForce "2256x1504,auto";

  boot.kernelParams = [
    "quiet"
    "i915.force_probe=46a6"
    "splash"
    "loglevel=3"

    # Enable deep sleep
    "mem_sleep_default=deep"

    # https://community.frame.work/t/linux-battery-life-tuning/6665/156
    "nvme.noacpi=1"
  ];

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/bf23029a-e7de-415a-bfa2-6999f826a8b0";
      preLVM = true;
    };
  };

  services.fprintd.enable = true;
  programs.light.enable = true;

  hardware.bluetooth = {
    enable = true;
    settings.General.experimental = true;
  };

  services.blueman.enable = true;
}
