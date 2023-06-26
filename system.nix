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

  patchIosevka = font:
    pkgs.stdenv.mkDerivation {
      name = "${font.name}-nerd-font";
      src = font;
      nativeBuildInputs = [pkgs.nerd-font-patcher];
      buildPhase = ''
        mkdir -p $out
        find . -type f \
          \( -name '*.ttf' -o -name '*.otf' \) \
          -not -name '*extended*' \
          -not -name '*thin*' \
          -not -name '*light*' \
          -not -name '*oblique*' \
          -exec nerd-font-patcher -c --no-progressbars --makegroups 4 -out $out {} \;
      '';
    };

  iosevka-happy = pkgs.iosevka.override {
    set = "happy";

    privateBuildPlan = {
      family = "Iosevka Happy";
      spacing = "term";
      serifs = "sans";
      no-cv-ss = true;
      export-glyph-names = false;

      variants = {
        design = {
          lig-hyphen-chain = "without-notch";
          lig-equal-chain = "without-notch";
        };
      };

      ligations = {
        inherits = "dlig";
        enables = ["eqeqeq" "exeqeqeq"];
      };
    };
  };

  iosevka-happy-nerd-font = patchIosevka iosevka-happy;
in {
  systemd.services.ModemManager.enable = false;

  system = {inherit stateVersion;};
  imports = [
    inputs.grub2-theme.nixosModules.default
    inputs.hyprland.nixosModules.default
  ];

  nix = {
    settings = {
      trusted-users = ["root" "happens"];

      substituters = [
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

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
    consoleLogLevel = 0;

    initrd = {
      verbose = false;
      systemd.enable = true;
    };

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
    zsh.enable = true;

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

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        fuse3
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        curl
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        webkitgtk
        librsvg
        libsoup
        libGL
        libappindicator-gtk3
        libdrm
        libnotify
        libpulseaudio
        libuuid
        libusb1
        xorg.libxcb
        libxkbcommon
        mesa
        nspr
        nss
        pango
        pipewire
        systemd
        icu
        openssl
        xorg.libX11
        xorg.libXScrnSaver
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libxkbfile
        xorg.libxshmfence
        zlib
      ];
    };
  };

  # See https://nixos.wiki/wiki/Command_Shell
  users.defaultUserShell = pkgs.zsh;
  environment = {
    enableAllTerminfo = true;
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

    pathsToLink = ["/share/zsh"];

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
    envfs.enable = true;

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
        hourly = 1;
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

  fonts = {
    fontconfig = {
      defaultFonts = {
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
        monospace = ["IosevkaHappy NF Medium"];
      };
    };

    fonts = with pkgs; [
      inter
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans
      iosevka-happy-nerd-font
    ];
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  fileSystems."/tmplocal" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "uid=1000" "gid=1000" "mode=755" "size=8G"];
  };
}
