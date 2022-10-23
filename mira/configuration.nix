{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostId = "3ef514cd";
  networking.hostName = "mira";

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";
    efiSupport = true;
    enableCryptodisk = true;
    theme = pkgs.nixos-grub2-theme;
  };

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/bf23029a-e7de-415a-bfa2-6999f826a8b0";
      preLVM = true;
    };
  };

  services.fprintd.enable = true;
}

