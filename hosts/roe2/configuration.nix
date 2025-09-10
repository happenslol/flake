{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  networking = {
    hostId = "640c2c0b";
    hostName = "roe2";
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
    ];
  };

  nix.settings = {
    cores = 6;
    max-jobs = 4;
  };

  hardware = {
    xpadneo.enable = true;

    bluetooth = {
      enable = true;
      settings.General.experimental = true;
    };
  };

  services = {
    blueman.enable = true;

    # TODO: Fix this
    # udev.extraRules = ''
    #   ACTION=="add", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="6940", ATTRS{idProduct}=="3137", SYMLINK+="corsair-h150i", TAG+="systemd"
    # '';
  };

  systemd.services.corsair-h150i-liquidctl = {
    enable = true;
    description = "CPU AIO Fan Control";
    wantedBy = ["default.target"];
    # requires = ["dev-corsair-h150i.device"];
    # after = ["dev-corsair-h150i.device"];

    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.liquidctl}/bin/liquidctl initialize --pump-mode quiet
      ${pkgs.liquidctl}/bin/liquidctl set fan speed 30 40 40 50 45 60 50 90
      ${pkgs.liquidctl}/bin/liquidctl set led color fixed 444444
    '';
  };
}
