{inputs, ...}: {
  imports = [inputs.nixos-hardware.nixosModules.framework-12th-gen-intel];

  networking = {
    hostId = "3ef514cd";
    hostName = "mira";
  };

  boot = {
    loader = {
      timeout = 0;
      efi.canTouchEfiVariables = true;

      systemd-boot = {
        enable = true;
        configurationLimit = 50;
      };
    };

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "nowatchdog"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "rd.systemd.show_status=false"

      "i915.force_probe=46a6"

      # Enable deep sleep
      "mem_sleep_default=deep"

      # https://community.frame.work/t/linux-battery-life-tuning/6665/156
      "nvme.noacpi=1"
    ];
  };

  programs.light.enable = true;

  hardware.bluetooth = {
    enable = true;
    settings.General.experimental = true;
  };

  services.blueman.enable = true;

  nix.settings = {
    cores = 4;
    max-jobs = 2;
  };
}
