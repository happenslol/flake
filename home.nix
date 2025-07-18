{
  config,
  pkgs,
  stateVersion,
  hostname,
  inputs,
  system,
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

  pk-agent = inputs.pk-agent.packages."${system}".default;

  custom = {
    codelldb = pkgs.writeShellScriptBin "codelldb" ''
      exec -a $0 ${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb $@
    '';

    npm-global = pkgs.callPackage ./npm-global {};
    serve = inputs.serve.packages.${system}.default;
    status = inputs.status.packages.${system}.default;
  };
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

    packages =
      (builtins.concatLists (builtins.attrValues (import ./packages.nix pkgs)))
      ++ (builtins.attrValues custom);

    file = {
      ".gitconfig".source = "${dotfiles}/git/gitconfig";
      ".gitattributes".source = "${dotfiles}/git/gitattributes";
      ".gitconfig-garage".source = "${dotfiles}/git/gitconfig-garage";
      ".gitconfig-opencreek".source = "${dotfiles}/git/gitconfig-opencreek";
      ".gitignore".source = "${dotfiles}/git/gitignore";
      ".ssh/config".source = "${dotfiles}/ssh/config";
      ".git-scripts".source = "${dotfiles}/git/scripts";
      ".cargo/config.toml".source = "${dotfiles}/cargo/config.toml";
    };

    pointerCursor = {
      gtk.enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  systemd.user.services = {
    polkit-agent = {
      Unit = {
        Description = "Polkit Agent";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };

      Install.WantedBy = ["graphical-session.target"];

      Service = {
        Type = "simple";
        ExecStart = "${pk-agent}/bin/pk-agent";
        Restart = "on-failure";
        Environment = [
          "XDG_SESSION_TYPE=wayland"
          "WAYLAND_DISPLAY=wayland-1"
          "GDK_BACKEND=wayland"
          "XDG_RUNTIME_DIR=/run/user/1000"
          "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
        ];
      };
    };
  };

  xdg = {
    configFile = {
      "host".source = hostDotfiles;
      "bat".source = "${dotfiles}/bat";
      "nvim".source = "${dotfiles}/nvim";
      "zsh".source = "${dotfiles}/zsh";
      "kitty".source = "${dotfiles}/kitty";
      "starship.toml".source = "${dotfiles}/starship/starship.toml";
      "hypr".source = "${dotfiles}/hypr";
      "tealdeer".source = "${dotfiles}/tealdeer";
      "mako".source = "${dotfiles}/mako";
      "lazygit/config.yml".source = "${dotfiles}/lazygit/config.yml";
      "btop/btop.conf".source = "${dotfiles}/btop/btop.conf";
      "btop/themes".source = "${dotfiles}/btop/themes";
      "direnv/direnv.toml".source = "${dotfiles}/direnv/direnv.toml";
      "pnpm/rc".source = "${dotfiles}/pnpm/rc";
      "zed".source = "${dotfiles}/zed";
    };

    systemDirs.data = [gsettingsDatadir];
  };

  gtk = {
    enable = true;
    theme.name = "Orchis-Dark";
    cursorTheme.name = "Bibata-Modern-Classic";
    iconTheme.name = "Qogir-dark";

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = ":menu";
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = ":menu";
    };
  };

  # Disable appmenu for gtk applications
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "appmenu:none";
}
