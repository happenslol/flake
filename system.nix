{
  config,
  pkgs,
  stateVersion,
  inputs,
  ...
}: let
  customPackages = {
    setup-hyprland-environment = pkgs.writeTextFile {
      name = "setup-hyprland-environment";
      destination = "/bin/setup-hyprland-environment";
      executable = true;

      text = ''
        systemctl --user import-environment
        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
          DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland \
          HYPRLAND_INSTANCE_SIGNATURE

        systemctl --user start graphical-session.target
      '';
    };
  };

  greetd = {
    gtkConfig = ''
      [Settings]
      gtk-application-prefer-dark-theme = true
      gtk-theme-name = Orchis-Dark
      gtk-cursor-theme-name = Bibata-Modern-Classic
      gtk-cursor-theme-size = 24
    '';

    swayConfig = pkgs.writeText "greetd-sway-config" ''
      input type:keyboard xkb_numlock enabled

      exec {
        systemctl --user import-environment
        "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK"
        "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l -c sway; swaymsg exit"
      }
    '';
  };
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

    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    hyprland = {
      enable = true;
      xwayland = {
        enable = true;
        hidpi = true;
      };
    };

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
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
      wayland
      glib
      wl-clipboard
      slurp
      grim
      wdisplays
      pulseaudio
      kanshi
      gnome.file-roller

      (orchis-theme.override {border-radius = 4;})
      qogir-icon-theme
      bibata-cursors
      customPackages.setup-hyprland-environment
    ];

    etc."greetd/environments".text = "Hyprland";
    etc."greetd/greeter_home/.config/gtk-3.0/settings.ini".text = greetd.gtkConfig;
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
          command = "${pkgs.sway}/bin/sway --config ${greetd.swayConfig}";
        };
      };
    };
  };

  users.users = {
    greeter.home = "/etc/greetd/greeter_home";

    happens = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "docker" "audio" "video"];
      shell = pkgs.zsh;
    };
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
  };

  security = {
    rtkit.enable = true;
    pam.services.gtklock = {};
  };

  virtualisation.docker.enable = true;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk-sans

    (nerdfonts.override {fonts = ["Iosevka"];})
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };
}
