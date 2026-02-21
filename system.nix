{
  config,
  pkgs,
  stateVersion,
  username,
  inputs,
  hostname,
  ...
}: let
  mkSopsSecrets = {
    file,
    owner ? null,
  }: let
    content = builtins.fromJSON (builtins.readFile file);

    collectPaths = prefix: attrs:
      builtins.concatLists (builtins.attrValues (builtins.mapAttrs (
          name: value:
            if name == "sops"
            then []
            else if builtins.isAttrs value
            then collectPaths "${prefix}${name}/" value
            else ["${prefix}${name}"]
        )
        attrs));

    paths = collectPaths "" content;
  in
    builtins.listToAttrs (map (path: {
        name = path;
        value =
          {sopsFile = file;}
          // (
            if owner != null
            then {inherit owner;}
            else {}
          );
      })
      paths);

  sshPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILKxWGDAzOaKWHDGILdbWFy+faN/X/LK+xwncd6+ysDW" # roe2.personal
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEt4XK+lj/LK2hswmcbqYCL62sU/HLawpFv2QbPoOyWn" # hei.personal
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPS2P0chvWgX5gvfIMKcaSLclj/Awowvqk3lwXHzy4HU" # mira.personal
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+OhmDhccVxUIjk90xOeS/7oX7JY8hpvKGufThO3LEL" # pixel.personal
  ];

  greetd = {
    gtkConfig = ''
      [Settings]
      gtk-application-prefer-dark-theme = true
      gtk-theme-name = Orchis-Dark
      gtk-cursor-theme-name = Bibata-Modern-Classic
      gtk-cursor-theme-size = 24
    '';

    swayConfig = pkgs.writeText "greetd-sway-config" ''
      exec "${pkgs.gtkgreet}/bin/gtkgreet -l; ${pkgs.swayfx}/bin/swaymsg exit"

      include ~/.config/sway/common.conf
      include ~/.config/host/sway/host.conf
    '';
  };
in {
  system = {inherit stateVersion;};

  systemd = {
    tmpfiles.rules = [
      "Z /etc/greetd - greeter greeter"
      "d /home/happens 0711 happens users -"
      "d /home/happens/media 2775 happens media -"
      "d /home/happens/transmission 2775 happens media -"
    ];

    services = {
      # See https://github.com/NixOS/nixpkgs/issues/180175
      NetworkManager-wait-online.enable = false;
      tailscaled.after = ["systemd-networkd-wait-online.service"];
      pia-vpn.after = ["systemd-networkd-wait-online.service"];

      transmission-dirs = {
        description = "Create Transmission download directories";
        requiredBy = ["transmission.service"];
        before = ["transmission.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p /home/happens/transmission/.incomplete && ${pkgs.coreutils}/bin/chown -R transmission:transmission /home/happens/transmission'";
        };
      };

      transmission = {
        bindsTo = ["pia-vpn.service"];
        after = ["pia-vpn.service"];
        serviceConfig = {
          NetworkNamespacePath = "/var/run/netns/pia";
          BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
        };
      };

      transmission-rpc-proxy = {
        description = "Forward Transmission RPC from pia namespace to host";
        after = ["transmission.service"];
        bindsTo = ["transmission.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:9091,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:9091'";
          Restart = "always";
        };
      };

      radarr = {
        bindsTo = ["pia-vpn.service"];
        after = ["pia-vpn.service"];
        serviceConfig = {
          NetworkNamespacePath = "/var/run/netns/pia";
          BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
        };
      };

      sonarr = {
        bindsTo = ["pia-vpn.service"];
        after = ["pia-vpn.service"];
        serviceConfig = {
          NetworkNamespacePath = "/var/run/netns/pia";
          BindReadOnlyPaths = ["/etc/netns/pia/resolv.conf:/etc/resolv.conf"];
        };
      };

      radarr-rpc-proxy = {
        description = "Forward Radarr from pia namespace to host";
        after = ["radarr.service"];
        bindsTo = ["radarr.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:7878,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:7878'";
          Restart = "always";
        };
      };

      sonarr-rpc-proxy = {
        description = "Forward Sonarr from pia namespace to host";
        after = ["sonarr.service"];
        bindsTo = ["sonarr.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8989,fork,reuseaddr EXEC:'${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.socat}/bin/socat STDIO TCP\\:127.0.0.1\\:8989'";
          Restart = "always";
        };
      };

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
      experimental-features = ["nix-command" "flakes" "pipe-operators"];

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
    extraOptions = "warn-dirty = false";

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

    kernelPackages = pkgs.linuxKernel.packages.linux_6_18;
    # Re-enable after https://github.com/NixOS/nixpkgs/issues/436300 lands
    # extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];

    supportedFilesystems = ["zfs" "ntfs"];
    zfs.package = pkgs.zfs_2_4;
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
    gamescope.enable = true;
    gamemode.enable = true;
    corectrl.enable = true;

    ssh.startAgent = true;
    dconf.enable = true;
    zsh.enable = true;

    sway = {
      enable = true;
      xwayland.enable = true;
      # package = pkgs.swayfx;
    };

    uwsm = {
      enable = true;
      waylandCompositors.sway = {
        prettyName = "Sway";
        binPath = "/run/current-system/sw/bin/sway";
      };
    };

    thunar = {
      enable = true;
      plugins = with pkgs; [
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
    # enableAllTerminfo = true;
    shells = [pkgs.zsh pkgs.bash];
    binsh = "${pkgs.dash}/bin/dash";

    systemPackages = with pkgs; [
      neovim
      curl
      kitty

      # Theme stuff
      (orchis-theme.override {border-radius = 4;})
      bibata-cursors
      qogir-icon-theme
    ];

    pathsToLink = ["/share/zsh"];

    etc = {
      "netns/pia/resolv.conf".text = "nameserver 10.0.0.243\n";
      "greetd/.icons/Bibata-Modern-Classic".source = "${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Classic";
      "greetd/.config/gtk-3.0/settings.ini".source = ./config/gtk3/settings.ini;
      "greetd/.config/sway".source = ./config/sway;
      "greetd/.config/host/sway".source = ./. + "/hosts/${hostname}/config/sway";
      "greetd/environments".text = "uwsm start -- /run/current-system/sw/bin/sway";
    };
  };

  services = {
    nginx = {
      enable = true;
      virtualHosts = {
        "transmission.local" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/".proxyPass = "http://127.0.0.1:9091";
        };
        "radarr.local" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/".proxyPass = "http://127.0.0.1:7878";
        };
        "sonarr.local" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/".proxyPass = "http://127.0.0.1:8989";
        };
      };
    };

    upower.enable = true;
    openssh.enable = true;
    dbus.enable = true;
    tumbler.enable = true;
    gvfs.enable = true;
    devmon.enable = true;
    udisks2.enable = true;
    envfs.enable = true;
    tailscale.enable = true;
    flatpak.enable = true;
    resolved.enable = true;
    gnome = {
      gnome-keyring.enable = true;
      gcr-ssh-agent.enable = false;
    };

    # Start xdg autostart services
    xserver.desktopManager.runXdgAutostartIfNone = true;

    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    sanoid = {
      enable = true;
      datasets = {
        "rpool/home" = {
          monthly = 1;
          daily = 10;
          hourly = 3;
          autosnap = true;
          autoprune = true;
        };

        "rpool/home/state" = {
          daily = 1;
          hourly = 1;
          autosnap = true;
          autoprune = true;
        };
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    greetd = {
      enable = true;
      settings.default_session.command = "${pkgs.swayfx}/bin/sway --config ${greetd.swayConfig}";
    };

    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
      };
    };

    transmission = {
      enable = true;
      home = "/var/lib/transmission";
      package = pkgs.transmission_4;
      settings = {
        download-dir = "/home/happens/transmission";
        incomplete-dir = "/home/happens/transmission/.incomplete";
        incomplete-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
      };
    };

    radarr.enable = true;
    sonarr.enable = true;

    pia-vpn = {
      enable = true;
      environmentFile = config.sops.secrets.pia.path;
      certificateFile = ./pia.ca.rsa.4096.crt;
      namespace = "pia";
      region = "de-frankfurt";
      portForward = {
        enable = true;
        script = ''
          ${pkgs.curl}/bin/curl -s http://127.0.0.1:9091/transmission/rpc \
            -H "$(${pkgs.curl}/bin/curl -s http://127.0.0.1:9091/transmission/rpc | ${pkgs.gnugrep}/bin/grep -oP 'X-Transmission-Session-Id: \S+')" \
            -d '{"method":"session-set","arguments":{"peer-port":'"$port"'}}'
        '';
      };
    };
  };

  users.groups.media = {};

  users.users = {
    greeter.home = "/etc/greetd";

    happens = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "docker" "audio" "video" "plugdev" "dialout" "uucp" "input" "transmission" "media"];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = sshPublicKeys;
    };

    radarr.extraGroups = ["media"];
    sonarr.extraGroups = ["media"];
    transmission.extraGroups = ["media"];
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
    hosts = {
      "127.0.0.1" = ["transmission.local" "radarr.local" "sonarr.local"];
    };
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
      monospace = ["Iosevka Term Nerd Font Complete Medium"];
    };

    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      nerd-fonts.iosevka-term
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];

    wlr = {
      enable = true;
      settings.screencast = {
        output_name = "DP-1";
        chooser_type = "simple";
        chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
      };
    };
  };

  hardware = {
    sane.enable = true;
    xpadneo.enable = true;
    steam-hardware.enable = true;
  };

  sops = {
    defaultSopsFile = ./secrets.json;
    environment.SOPS_AGE_SSH_PRIVATE_KEY_FILE = "/home/${username}/.ssh/${hostname}.personal.id_ed25519";
    secrets = mkSopsSecrets {
      file = ./secrets.json;
      owner = username;
    };
  };
}
