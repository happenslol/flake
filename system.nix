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

  greetd = {
    gtkConfig = ''
      [Settings]
      gtk-application-prefer-dark-theme = true
      gtk-theme-name = Orchis-Dark
      gtk-cursor-theme-name = Bibata-Modern-Classic
      gtk-cursor-theme-size = 24
    '';

    hyprlandConfig = pkgs.writeText "greetd-hyprland-config" ''
      $mod = SUPER

      animations {
        enabled = false
      }

      source = ~/.config/hypr/common.conf
      source = ~/.config/host/hypr/hyprland.conf

      exec-once = ${pkgs.greetd.gtkgreet}/bin/gtkgreet -l; hyprctl dispatch exit
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

  iosevka-happy = pkgs-pinned.iosevka.override {
    set = "happy";

    privateBuildPlan = {
      family = "Iosevka Happy";
      spacing = "term";
      serifs = "sans";
      noCvSs = false;
      exportGlyphNames = true;

      variants.design = {
        lig-ltgteq = "slanted";
        lig-hyphen-chain = "without-notch";
        lig-equal-chain = "without-notch";
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

  systemd = {
    tmpfiles.rules = ["Z /etc/greetd - greeter greeter"];

    user.targets.hyprland-session = {
      description = "Hyprland compositor session";
      documentation = ["man:systemd.special(7)"];
      bindsTo = ["graphical-session.target"];
      wants = ["graphical-session-pre.target"];
      after = ["graphical-session-pre.target"];
    };

    services = {
      # See https://github.com/NixOS/nixpkgs/issues/180175
      NetworkManager-wait-online.enable = false;

      # See https://github.com/openzfs/zfs/issues/10891
      # Our root is on pool, so our pools are already imported whenever this
      # service would run.
      systemd-udev-settle.enable = false;

      # See https://bbs.archlinux.org/viewtopic.php?id=295916
      sleep-rfkill = {
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
  };

  nix = {
    registry.nixkpgs.flake = inputs.nixpkgs;
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

    # Increase max vm map count for nodejs workers running out of heap memory
    kernel.sysctl = {"vm.max_map_count" = 262144;};

    kernelPackages = pkgs.linuxKernel.packages.linux_6_14;
    extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];

    supportedFilesystems = ["zfs" "ntfs"];
  };

  time = {
    timeZone = "Europe/Berlin";
    hardwareClockInLocalTime = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";

    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-mozc
          fcitx5-anthy
          fcitx5-gtk
        ];
      };

      ibus.engines = with pkgs.ibus-engines; [anthy];
    };
  };

  programs = {
    command-not-found.enable = false;
    nix-index-database.comma.enable = true;
    steam.enable = true;
    corectrl.enable = true;

    ssh.startAgent = true;
    dconf.enable = true;
    zsh.enable = true;

    hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    xwayland.enable = pkgs.lib.mkForce true;

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
      package = pkgs._1password-gui-beta;
    };

    nix-ld = {
      enable = true;
      libraries = builtins.concatLists (builtins.attrValues (import ./ld.nix pkgs));
    };
  };

  # See https://nixos.wiki/wiki/Command_Shell
  users.defaultUserShell = pkgs.zsh;

  environment = {
    enableAllTerminfo = true;
    shells = [pkgs.zsh pkgs.bash];
    binsh = "${pkgs.dash}/bin/dash";

    systemPackages = with pkgs; [
      neovim
      curl
      kitty

      setup-hyprland-environment

      # Theme stuff
      (orchis-theme.override {border-radius = 4;})
      bibata-cursors
      niqs.bibata-hyprcursor
      qogir-icon-theme
    ];

    pathsToLink = ["/share/zsh"];

    etc."greetd/.icons/Bibata-Modern-Classic".source = "${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic";
    etc."greetd/.config/gtk-3.0/settings.ini".source = ./config/gtk3/settings.ini;
    etc."greetd/.config/hypr".source = ./config/hypr;
    etc."greetd/.config/host/hypr".source = ./. + "/hosts/${hostname}/config/hypr";
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

    # Start xdg autostart services
    xserver.desktopManager.runXdgAutostartIfNone = true;

    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    sanoid = {
      enable = true;
      datasets."rpool/home" = {
        monthly = 1;
        daily = 10;
        hourly = 1;
        autosnap = true;
        autoprune = true;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    greetd = {
      enable = true;
      settings.default_session.command = "${pkgs.hyprland}/bin/Hyprland -c ${greetd.hyprlandConfig}";
    };

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
      extraGroups = ["wheel" "networkmanager" "docker" "audio" "video"];
      shell = pkgs.zsh;
    };
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
  };

  security.rtkit.enable = true;

  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
    autoPrune.enable = true;
  };

  fonts = {
    fontconfig.defaultFonts = {
      sansSerif = ["Noto Sans"];
      serif = ["Noto Serif"];
      monospace = ["IosevkaHappy NF Medium"];
    };

    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans
      iosevka-happy-nerd-font
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
    wlr.enable = pkgs.lib.mkForce false;
  };

  hardware.sane.enable = true;
}
