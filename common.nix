{ config, pkgs, ... }:

{
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

  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
  };

  # See https://nixos.wiki/wiki/Command_Shell
  users.defaultUserShell = pkgs.zsh;
  environment.shells = with pkgs; [ zsh ];
  environment.binsh = "${pkgs.dash}/bin/dash";

  users.users.happens = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [ vim wget git ];

  services.openssh.enable = true;
  networking.firewall.enable = false;

  programs.sway.enable = true;
  programs.ssh.startAgent = true;
  virtualisation.docker.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts noto-fonts-emoji
    noto-fonts-cjk-sans

    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  system.stateVersion = "22.05";
}
