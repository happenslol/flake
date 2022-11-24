{ config, pkgs, stateVersion, ... }:

{
  imports = [
    ./grub.nix
    ./greetd.nix
    ./sway.nix
    ./zfs.nix
    ./thunar.nix
  ];

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  boot.plymouth.enable = true;
  boot.initrd.systemd.enable = true;

  # Increase max vm map count for nodejs workers
  # running out of heap memory
  boot.kernel.sysctl = { "vm.max_map_count" = 262144; };

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.dconf.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
  };

  # See https://nixos.wiki/wiki/Command_Shell
  users.defaultUserShell = pkgs.zsh;
  environment.shells = [ pkgs.zsh pkgs.bash ];
  environment.binsh = "${pkgs.dash}/bin/dash";

  users.users.happens = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "audio"
      "video"
    ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [ vim wget curl ];

  services.openssh.enable = true;
  networking.firewall.enable = false;
  security.rtkit.enable = true;

  programs.ssh.startAgent = true;
  virtualisation.docker.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts noto-fonts-emoji
    noto-fonts-cjk-sans

    (nerdfonts.override { fonts = [ "JetBrainsMono" "Iosevka" ]; })
  ];

  system = { inherit stateVersion; };
}
