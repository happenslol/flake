{
  config,
  pkgs,
  stateVersion,
  inputs,
  ...
}: let
  greetd-sway-config = pkgs.writeText "greetd-sway-config" ''
    exec systemctl --user import-environment
    exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
    exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l -c sway; swaymsg exit"

    input type:keyboard xkb_numlock enabled
  '';

  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema=org.gnome.desktop.interface
    '';
  };

  wayland-session = pkgs.writeShellScriptBin "wayland-session" ''
    /run/current-system/systemd/bin/systemctl --user start graphical-session.target
    "$@"
    /run/current-system/systemd/bin/systemctl --user stop graphical-session.target
  '';
in {
  system = {inherit stateVersion;};
  imports = [
    inputs.grub2-theme.nixosModules.default
    inputs.hyprland.nixosModules.default
  ];

  nix = {
    settings.trusted-users = ["root" "happens"];

    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  boot = {
    plymouth.enable = true;
    initrd.systemd.enable = true;

    # Increase max vm map count for nodejs workers
    # running out of heap memory
    kernel.sysctl = {"vm.max_map_count" = 262144;};

    # Use latest kernel compatible with zfs
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    # Enable zfs and ntfs3g
    supportedFilesystems = ["zfs" "ntfs"];

    loader = {
      grub = {
        enable = true;
        version = 2;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = true;
      };

      grub2-theme = {
        enable = true;
        resolution = "2560x1440";
      };
    };
  };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  programs = {
    ssh.startAgent = true;
    dconf.enable = true;

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    hyprland = {
      enable = true;
      xwayland.hidpi = true;
    };

    zsh = {
      enable = true;
      autosuggestions.enable = true;
    };
  };

  # See https://nixos.wiki/wiki/Command_Shell
  users.defaultUserShell = pkgs.zsh;
  environment = {
    shells = [pkgs.zsh pkgs.bash];
    binsh = "${pkgs.dash}/bin/dash";
    systemPackages = with pkgs; [
      vim
      wget
      curl
      swww
      sway
      wayland
      glib
      swaylock
      swayidle
      wl-clipboard
      waybar
      slurp
      grim
      wdisplays
      pulseaudio
      kanshi
      xarchiver
      configure-gtk
      dbus-sway-environment
      wayland-session
    ];

    etc."greetd/environments".text = ''
      wayland-session sway
      wayland-session Hyprland
    '';
  };

  services = {
    upower.enable = true;
    openssh.enable = true;
    dbus.enable = true;
    tumbler.enable = true;
    gvfs.enable = true;
    devmon.enable = true;
    udisks2.enable = true;

    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    sanoid = {
      enable = true;
      datasets."rpool/user" = {
        recursive = true;
        monthly = 1;
        daily = 10;
        hourly = 0;
        autosnap = true;
        autoprune = true;
        processChildrenOnly = true;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.sway}/bin/sway --config ${greetd-sway-config}";
        };
      };
    };
  };

  users.users.happens = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "docker" "audio" "video"];
    shell = pkgs.zsh;
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
  };

  security.rtkit.enable = true;

  virtualisation.docker.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk-sans

    (nerdfonts.override {fonts = ["JetBrainsMono" "Iosevka"];})
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
