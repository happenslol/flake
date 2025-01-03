{
  config,
  pkgs,
  pkgs-pinned,
  stateVersion,
  username,
  inputs,
  hostname,
  niqs,
  ...
}: let
  customPackages = {
    setup-hyprland-environment = pkgs.writeTextFile {
      name = "setup-hyprland-environment";
      destination = "/bin/setup-hyprland-environment";
      executable = true;

      text = ''
        #!/usr/bin/env bash
        ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
          DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland \
          HYPRLAND_INSTANCE_SIGNATURE

        systemctl --user import-environment \
          DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        systemctl --user start hyprland-session.target

        # The desktop portal does not find applications if we don't do this.
        # See: https://discourse.nixos.org/t/open-links-from-flatpak-via-host-firefox/15465/11
        systemctl --user import-environment PATH
        systemctl --user restart xdg-desktop-portal.service
      '';
    };

    session = pkgs.writeTextFile {
      name = "setup-hyprland-environment";
      destination = "/bin/hyprland-session";
      executable = true;

      text = ''
        #!/usr/bin/env bash
        ${pkgs.hyprland}/bin/hyprland > /dev/null 2>&1
      '';
    };
  };

  # dash2 = inputs.dash2.packages."${system}".default;

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
        "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK"
        "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l -c sway; swaymsg exit"
      }
    '';
  };

  patchIosevka = font:
    pkgs-pinned.stdenv.mkDerivation {
      name = "${font.name}-nerd-font";
      src = font;
      nativeBuildInputs = [pkgs-pinned.nerd-font-patcher];
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

  # [buildPlans.IosevkaHappy]
  # family = "Iosevka Happy"
  # spacing = "term"
  # serifs = "sans"
  # noCvSs = false
  # exportGlyphNames = true
  #
  # [buildPlans.IosevkaHappy.variants.design]
  # lig-ltgteq = "slanted"
  # lig-equal-chain = "without-notch"
  # lig-hyphen-chain = "without-notch"
  #
  # inherits = "dlig"
  # [buildPlans.IosevkaHappy.ligations]

  iosevka-happy = pkgs-pinned.iosevka.override {
    set = "happy";

    privateBuildPlan = {
      family = "Iosevka Happy";
      spacing = "term";
      serifs = "sans";
      noCvSs = false;
      exportGlyphNames = true;

      variants = {
        design = {
          lig-ltgteq = "slanted";
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
  system = {inherit stateVersion;};
  imports = [
    inputs.grub2-theme.nixosModules.default
    inputs.hyprland.nixosModules.default
  ];

  systemd = {
    tmpfiles.rules = [
      "Z /etc/greetd - greeter greeter"

      "d /nosync       0755 ${username} users -"
      "d /nosync/atuin 0755 ${username} users -"
    ];

    user.targets.hyprland-session = {
      description = "Hyprland compositor session";
      documentation = ["man:systemd.special(7)"];
      bindsTo = ["graphical-session.target"];
      wants = ["graphical-session-pre.target"];
      after = ["graphical-session-pre.target"];
    };

    # See https://github.com/NixOS/nixpkgs/issues/180175
    services.NetworkManager-wait-online.enable = false;

    # See https://bbs.archlinux.org/viewtopic.php?id=295916
    services.sleep-rfkill = {
      description = "Disable bluetooth and wifi while suspended";
      before = ["sleep.target"];
      wantedBy = ["sleep.target"];

      unitConfig.StopWhenUnneeded = "yes";
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = "${pkgs.util-linux}/bin/rfkill block bluetooth wifi";
        ExecStop = "${pkgs.util-linux}/bin/rfkill unblock bluetooth wifi";
      };
    };
  };

  nix = {
    nixPath = ["nixpkgs=${inputs.nixpkgs.outPath}"];

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

    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
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

    kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
    extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];

    # Enable zfs and ntfs3g
    supportedFilesystems = ["zfs" "ntfs"];

    loader = {
      efi.canTouchEfiVariables = false;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = true;
        efiInstallAsRemovable = true;
      };

      grub2-theme = {
        enable = true;
        resolution = "3840x2160";
      };
    };
  };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  programs = {
    command-not-found.enable = false;
    nix-index-database.comma.enable = true;
    steam.enable = true;

    ssh.startAgent = true;
    dconf.enable = true;
    zsh.enable = true;

    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };

    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["${username}"];
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
      kitty
      wayland
      glib
      wl-clipboard
      slurp
      grim
      wdisplays
      pulseaudio
      kanshi
      file-roller
      lm_sensors

      (orchis-theme.override {border-radius = 4;})
      qogir-icon-theme
      customPackages.setup-hyprland-environment
      customPackages.session
      bibata-cursors
      niqs.bibata-hyprcursor
      gtk3
      # dash2
    ];

    pathsToLink = ["/share/zsh"];

    etc."greetd/.icons/default/index.theme".text = ''
      [Icon Theme
      Name=Default
      Comment=Default Cursor Theme
      Inherits=Bibata-Modern-Classic
    '';

    etc."greetd/.icons/Bibata-Modern-Classic".source = "${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic";
    etc."greetd/.config/gtk-3.0/settings.ini".source = ./config/gtk3/settings.ini;
    etc."greetd/.config/hypr".source = ./config/hypr;
    etc."greetd/.config/host/hypr".source = ./. + "/hosts/${hostname}/config/hypr";
    etc."greetd/environments".text = "Hyprland";
    # etc."dash2".source = ./. + "/hosts/${hostname}/config/dash2";
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

    # TODO: Fix this
    # greetd = {
    #   enable = true;
    #   settings.default_session.command = "hyprland -c ~/.config/hypr/greeter.conf > /dev/null 2>&1";
    # };

    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  users.users = {
    greeter.home = "/etc/greetd";

    happens = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "docker" "audio" "video" "vboxusers"];
      shell = pkgs.zsh;
    };
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;

    hosts = {
      "127.0.0.1" = ["copernicus-dev-rds.cluster-cm8mhsxz88cx.eu-central-1.rds.amazonaws.com"];
    };
  };

  security = {
    rtkit.enable = true;
    pam.services.gtklock = {};
    pam.services.dash3 = {};
    # pam.services.dash2 = {};
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
  };

  fonts = {
    fontconfig = {
      defaultFonts = {
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
        monospace = ["IosevkaHappy NF Medium"];
      };
    };

    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans
      iosevka-happy-nerd-font
    ];
  };

  # TODO: Why does this install xdg-desktop-portal-wlr
  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];

    wlr.enable = pkgs.lib.mkForce false;
  };

  fileSystems."/home/${username}/.local/share/atuin" = {
    device = "/nosync/atuin";
    options = ["bind"];
  };

  hardware.sane.enable = true;
}
# {
#   config,
#   pkgs,
#   pkgs-stable,
#   stateVersion,
#   username,
#   inputs,
#   ...
# }: let
#   customPackages = {
#     setup-hyprland-environment = pkgs.writeTextFile {
#       name = "setup-hyprland-environment";
#       destination = "/bin/setup-hyprland-environment";
#       executable = true;
#
#       text = ''
#         ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
#           DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland \
#           HYPRLAND_INSTANCE_SIGNATURE
#
#         systemctl --user import-environment \
#           DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
#         systemctl --user start hyprland-session.target
#
#         # The desktop portal does not find applications if we don't do this.
#         # See: https://discourse.nixos.org/t/open-links-from-flatpak-via-host-firefox/15465/11
#         systemctl --user import-environment PATH
#         systemctl --user restart xdg-desktop-portal.service
#       '';
#     };
#   };
#
#   greetd = {
#     gtkConfig = ''
#       [Settings]
#       gtk-application-prefer-dark-theme = true
#       gtk-theme-name = Orchis-Dark
#       gtk-cursor-theme-name = Bibata-Modern-Classic
#       gtk-cursor-theme-size = 24
#     '';
#
#     swayConfig = pkgs.writeText "greetd-sway-config" ''
#       input type:keyboard xkb_numlock enabled
#
#       exec {
#         "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK"
#         "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l -c sway; swaymsg exit"
#       }
#     '';
#   };
#
#   patchIosevka = font:
#     pkgs-stable.stdenv.mkDerivation {
#       name = "${font.name}-nerd-font";
#       src = font;
#       nativeBuildInputs = [pkgs-stable.nerd-font-patcher];
#       buildPhase = ''
#         mkdir -p $out
#         find . -type f \
#           \( -name '*.ttf' -o -name '*.otf' \) \
#           -not -name '*extended*' \
#           -not -name '*thin*' \
#           -not -name '*light*' \
#           -not -name '*oblique*' \
#           -exec nerd-font-patcher -c --no-progressbars --makegroups 4 -out $out {} \;
#       '';
#     };
#
#   # [buildPlans.IosevkaHappy]
#   # family = "Iosevka Happy"
#   # spacing = "term"
#   # serifs = "sans"
#   # noCvSs = false
#   # exportGlyphNames = true
#   #
#   # [buildPlans.IosevkaHappy.variants.design]
#   # lig-ltgteq = "slanted"
#   # lig-equal-chain = "without-notch"
#   # lig-hyphen-chain = "without-notch"
#   #
#   # inherits = "dlig"
#   # [buildPlans.IosevkaHappy.ligations]
#
#   iosevka-happy = pkgs-stable.iosevka.override {
#     set = "happy";
#
#     privateBuildPlan = {
#       family = "Iosevka Happy";
#       spacing = "term";
#       serifs = "sans";
#       noCvSs = false;
#       exportGlyphNames = true;
#
#       variants = {
#         design = {
#           lig-ltgteq = "slanted";
#           lig-hyphen-chain = "without-notch";
#           lig-equal-chain = "without-notch";
#         };
#       };
#
#       ligations = {
#         inherits = "dlig";
#         enables = ["eqeqeq" "exeqeqeq"];
#       };
#     };
#   };
#
#   iosevka-happy-nerd-font = patchIosevka iosevka-happy;
# in {
#   system = {inherit stateVersion;};
#   imports = [
#     inputs.grub2-theme.nixosModules.default
#     inputs.hyprland.nixosModules.default
#   ];
#
#   systemd = {
#     tmpfiles.rules = [
#       "d /nosync       0755 ${username} users -"
#       "d /nosync/atuin 0755 ${username} users -"
#     ];
#
#     user.targets.hyprland-session = {
#       description = "Hyprland compositor session";
#       documentation = ["man:systemd.special(7)"];
#       bindsTo = ["graphical-session.target"];
#       wants = ["graphical-session-pre.target"];
#       after = ["graphical-session-pre.target"];
#     };
#
#     # See https://github.com/NixOS/nixpkgs/issues/180175
#     services.NetworkManager-wait-online.enable = false;
#   };
#
#   nix = {
#     nixPath = ["nixpkgs=${inputs.nixpkgs.outPath}"];
#
#     settings = {
#       trusted-users = ["root" "happens"];
#
#       substituters = [
#         "https://nix-community.cachix.org"
#         "https://hyprland.cachix.org"
#       ];
#       trusted-public-keys = [
#         "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
#         "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
#       ];
#     };
#
#     package = pkgs.nixFlakes;
#     extraOptions = ''
#       experimental-features = nix-command flakes
#       warn-dirty = false
#     '';
#
#     settings.auto-optimise-store = true;
#     gc = {
#       automatic = true;
#       dates = "weekly";
#       options = "--delete-older-than 14d";
#     };
#   };
#
#   boot = {
#     plymouth.enable = true;
#     consoleLogLevel = 0;
#
#     initrd = {
#       verbose = false;
#       systemd.enable = true;
#     };
#
#     # Increase max vm map count for nodejs workers
#     # running out of heap memory
#     kernel.sysctl = {"vm.max_map_count" = 262144;};
#
#     # Use latest kernel compatible with zfs
#     kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
#     extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
#
#     # Enable zfs and ntfs3g
#     supportedFilesystems = ["zfs" "ntfs"];
#
#     loader = {
#       efi.canTouchEfiVariables = false;
#       grub = {
#         enable = true;
#         device = "nodev";
#         efiSupport = true;
#         enableCryptodisk = true;
#         efiInstallAsRemovable = true;
#       };
#
#       grub2-theme = {
#         enable = true;
#         resolution = "2560x1440";
#       };
#     };
#   };
#
#   time.timeZone = "Europe/Berlin";
#   i18n.defaultLocale = "en_US.UTF-8";
#
#   programs = {
#     coolercontrol.enable = true;
#     command-not-found.enable = false;
#     nix-index-database.comma.enable = true;
#     steam.enable = true;
#
#     ssh.startAgent = true;
#     dconf.enable = true;
#     zsh.enable = true;
#
#     sway = {
#       enable = true;
#       wrapperFeatures.gtk = true;
#     };
#
#     hyprland = {
#       enable = true;
#       xwayland.enable = true;
#     };
#
#     thunar = {
#       enable = true;
#       plugins = with pkgs.xfce; [
#         thunar-archive-plugin
#         thunar-volman
#       ];
#     };
#
#     nix-ld = {
#       enable = true;
#       libraries = with pkgs; [
#         stdenv.cc.cc
#         fuse3
#         alsa-lib
#         at-spi2-atk
#         at-spi2-core
#         atk
#         cairo
#         cups
#         curl
#         dbus
#         expat
#         fontconfig
#         freetype
#         gdk-pixbuf
#         glib
#         gtk3
#         webkitgtk
#         librsvg
#         libsoup
#         libGL
#         libappindicator-gtk3
#         libdrm
#         libnotify
#         libpulseaudio
#         libuuid
#         libusb1
#         xorg.libxcb
#         libxkbcommon
#         mesa
#         nspr
#         nss
#         pango
#         pipewire
#         systemd
#         icu
#         openssl
#         xorg.libX11
#         xorg.libXScrnSaver
#         xorg.libXcomposite
#         xorg.libXcursor
#         xorg.libXdamage
#         xorg.libXext
#         xorg.libXfixes
#         xorg.libXi
#         xorg.libXrandr
#         xorg.libXrender
#         xorg.libXtst
#         xorg.libxkbfile
#         xorg.libxshmfence
#         zlib
#       ];
#     };
#   };
#
#   # See https://nixos.wiki/wiki/Command_Shell
#   users.defaultUserShell = pkgs.zsh;
#   environment = {
#     enableAllTerminfo = true;
#     shells = [pkgs.zsh pkgs.bash];
#     binsh = "${pkgs.dash}/bin/dash";
#
#     systemPackages = with pkgs; [
#       vim
#       wget
#       curl
#       swww
#       wayland
#       glib
#       wl-clipboard
#       slurp
#       grim
#       wdisplays
#       pulseaudio
#       kanshi
#       file-roller
#       lm_sensors
#
#       (orchis-theme.override {border-radius = 4;})
#       qogir-icon-theme
#       bibata-cursors
#       customPackages.setup-hyprland-environment
#     ];
#
#     pathsToLink = ["/share/zsh"];
#
#     etc."greetd/environments".text = "Hyprland";
#     etc."greetd/greeter_home/.config/gtk-3.0/settings.ini".text = greetd.gtkConfig;
#     etc."dash2".source = ./config/dash2;
#   };
#
#   services = {
#     upower.enable = true;
#     openssh.enable = true;
#     dbus.enable = true;
#     tumbler.enable = true;
#     gvfs.enable = true;
#     devmon.enable = true;
#     udisks2.enable = true;
#     envfs.enable = true;
#
#     zfs = {
#       autoScrub.enable = true;
#       trim.enable = true;
#     };
#
#     sanoid = {
#       enable = true;
#       datasets."rpool/user" = {
#         recursive = true;
#         monthly = 1;
#         daily = 10;
#         hourly = 1;
#         autosnap = true;
#         autoprune = true;
#         processChildrenOnly = true;
#       };
#     };
#
#     pipewire = {
#       enable = true;
#       alsa.enable = true;
#       pulse.enable = true;
#     };
#
#     greetd = {
#       enable = true;
#       settings = {
#         default_session = {
#           command = "${pkgs.sway}/bin/sway --config ${greetd.swayConfig}";
#         };
#       };
#     };
#   };
#
#   users.users = {
#     greeter.home = "/etc/greetd/greeter_home";
#
#     happens = {
#       isNormalUser = true;
#       extraGroups = ["wheel" "networkmanager" "docker" "audio" "video" "vboxusers"];
#       shell = pkgs.zsh;
#     };
#   };
#
#   networking = {
#     networkmanager.enable = true;
#     firewall.enable = false;
#
#     hosts = {
#       "127.0.0.1" = ["copernicus-dev-rds.cluster-cm8mhsxz88cx.eu-central-1.rds.amazonaws.com"];
#     };
#   };
#
#   security = {
#     rtkit.enable = true;
#     pam.services.gtklock = {};
#     pam.services.dash2 = {};
#   };
#
#   virtualisation.docker = {
#     enable = true;
#     storageDriver = "overlay2";
#   };
#
#   fonts = {
#     fontconfig = {
#       defaultFonts = {
#         sansSerif = ["Noto Sans"];
#         serif = ["Noto Serif"];
#         monospace = ["IosevkaHappy NF Medium"];
#       };
#     };
#
#     packages = with pkgs; [
#       inter
#       noto-fonts
#       noto-fonts-emoji
#       noto-fonts-cjk-sans
#       iosevka-happy-nerd-font
#     ];
#   };
#
#   # TODO: Why does this install xdg-desktop-portal-wlr
#   xdg.portal = {
#     enable = true;
#     extraPortals = [pkgs.xdg-desktop-portal-gtk];
#
#     wlr.enable = pkgs.lib.mkForce false;
#   };
#
#   fileSystems."/home/${username}/.local/share/atuin" = {
#     device = "/nosync/atuin";
#     options = ["bind"];
#   };
# }

