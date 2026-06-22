{
  config,
  pkgs,
  stateVersion,
  hostname,
  username,
  ...
}: let
  home = "/home/${username}";
  dotfiles =
    config.lib.file.mkOutOfStoreSymlink "${home}/.flake/config";
  hostDotfiles =
    config.lib.file.mkOutOfStoreSymlink "${home}/.flake/hosts/${hostname}/config";

  gsettingsSchemas = pkgs.gsettings-desktop-schemas;
  gsettingsDatadir = "${gsettingsSchemas}/share/gsettings-schemas/${gsettingsSchemas.name}";

  # Unwrapped GTK 3 apps (e.g. gimp) launched via systemd/niri need the gtk3
  # schema (org.gtk.Settings.FileChooser) and a gdk-pixbuf svg loader in the
  # user-manager env, else they abort on startup. Fed in via environment.d below.
  gtk3Datadir = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";

  # gdk-pixbuf loaders (raster) + librsvg's svg loader.
  gdkPixbufLoaders =
    pkgs.runCommand "gdk-pixbuf-loaders.cache" {
      nativeBuildInputs = [pkgs.gdk-pixbuf.dev];
    } ''
      gdk-pixbuf-query-loaders \
        ${pkgs.gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders/*.so \
        ${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders/*.so \
        > $out
    '';
in {
  programs = {
    home-manager.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      enableVteIntegration = true;
      initContent = "source $HOME/.config/zsh/init.zsh";
    };
  };

  services.easyeffects = {
    enable = true;
    preset = "default";
  };

  home = {
    inherit stateVersion username;
    homeDirectory = home;

    sessionVariables = let
      browsers = pkgs.playwright-driver.browsers;
      chromium-rev =
        (builtins.head (builtins.filter (x: x.name == "chromium")
            (builtins.fromJSON (builtins.readFile "${pkgs.playwright-driver}/browsers.json")).browsers)).revision;
    in {
      PLAYWRIGHT_BROWSERS_PATH = "${browsers}";
      PLAYWRIGHT_MCP_EXECUTABLE_PATH = "${browsers}/chromium-${chromium-rev}/chrome-linux64/chrome";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";
      PLAYWRIGHT_HOST_PLATFORM_OVERRIDE = "ubuntu-24.04";
    };

    packages =
      builtins.concatLists (builtins.attrValues (import ./packages.nix pkgs));

    file = {
      ".gitconfig".source = "${dotfiles}/git/gitconfig";
      ".gitattributes".source = "${dotfiles}/git/gitattributes";
      ".gitconfig-garage".source = "${dotfiles}/git/gitconfig-garage";
      ".gitconfig-opencreek".source = "${dotfiles}/git/gitconfig-opencreek";
      ".gitignore".source = "${dotfiles}/git/gitignore";
      ".ssh/config".source = "${dotfiles}/ssh/config";
      ".git-scripts".source = "${dotfiles}/git/scripts";
      ".cargo/config.toml".source = "${dotfiles}/cargo/config.toml";
      ".tmux.conf".source = "${dotfiles}/tmux/tmux.conf";
      ".claude/settings.json".source = "${dotfiles}/claude/settings.json";
      ".claude-oc/settings.json".source = "${dotfiles}/claude/settings-oc.json";
      ".pi/agent/settings.json".source = "${dotfiles}/pi/settings.json";
      ".pi/agent/keybindings.json".source = "${dotfiles}/pi/keybindings.json";
      ".pi/agent/extensions".source = "${dotfiles}/pi/extensions";
    };

    pointerCursor = {
      gtk.enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  systemd.user.services = {
    status = {
      Install.WantedBy = ["graphical-session.target"];
      Unit = {
        Description = "Status";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.status}/bin/status";
        Restart = "on-failure";
        Environment = [];

        # NOTE: Prob need this for dbus
        # "XDG_RUNTIME_DIR=/run/user/1000"
        # "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      };
    };
  };

  xdg = {
    configFile = {
      "host".source = hostDotfiles;
      "scripts".source = "${dotfiles}/scripts";
      "bat".source = "${dotfiles}/bat";
      "nvim".source = "${dotfiles}/nvim";
      "zsh".source = "${dotfiles}/zsh";
      "kitty".source = "${dotfiles}/kitty";
      "ghostty".source = "${dotfiles}/ghostty";
      "starship.toml".source = "${dotfiles}/starship/starship.toml";
      "sway".source = "${dotfiles}/sway";
      "niri".source = "${dotfiles}/niri";
      "tealdeer".source = "${dotfiles}/tealdeer";
      "mako".source = "${dotfiles}/mako";
      "lazygit/config.yml".source = "${dotfiles}/lazygit/config.yml";
      "btop/btop.conf".source = "${dotfiles}/btop/btop.conf";
      "btop/themes".source = "${dotfiles}/btop/themes";
      "direnv/direnv.toml".source = "${dotfiles}/direnv/direnv.toml";
      "pnpm/rc".source = "${dotfiles}/pnpm/rc";
      "zed".source = "${dotfiles}/zed";
      "xkb".source = "${dotfiles}/xkb";
      "xdg-desktop-portal".source = "${dotfiles}/xdg-desktop-portal";
      "status".source = "${hostDotfiles}/status";
      "ccstatusline/settings.json".source = "${dotfiles}/claude/ccstatusline.json";
      "atuin".source = "${dotfiles}/atuin";

      # Read by the systemd user manager → niri and everything it spawns.
      "environment.d/90-gtk-pixbuf-loaders.conf".text = ''
        GDK_PIXBUF_MODULE_FILE=${gdkPixbufLoaders}
      '';
    };

    systemDirs.data = [gsettingsDatadir gtk3Datadir];
  };

  gtk = {
    enable = true;
    theme = {
      name = "Orchis-Dark";
      package = pkgs.orchis-theme.override {border-radius = 4;};
    };
    cursorTheme.name = "Bibata-Modern-Classic";
    iconTheme = {
      name = "Qogir-Dark";
      package = pkgs.qogir-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = ":menu";
    };

    gtk4.theme = config.gtk.theme;
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = ":menu";
    };
  };

  # Disable appmenu for gtk applications
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "appmenu:none";
}
