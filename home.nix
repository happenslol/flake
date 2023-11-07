{
  config,
  pkgs,
  lib,
  pkgs-nodejs_19,
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

  customPackages = {
    neovim-nightly = let
      neovim-nightly = inputs.neovim-nightly-overlay.packages.${system}.neovim;
    in (pkgs.writeShellScriptBin "nvim-nightly" "exec -a $0 ${neovim-nightly}/bin/nvim $@");
  };

  wezterm-custom = inputs.wezterm.packages."${system}".default;
  atuin-custom = inputs.atuin.packages."${system}".default;

  gsettingsSchemas = pkgs.gsettings-desktop-schemas;
  gsettingsDatadir = "${gsettingsSchemas}/share/gsettings-schemas/${gsettingsSchemas.name}";

  globalNpmPackages = [
    "pnpm@8.7.6"
    "@fsouza/prettierd@0.24.1"
  ];

  atuin-tmpfs = pkgs.writeShellScript "atuin-tmpfs" ''
    echo "Running atuin tmpfs sync"
    ${pkgs.coreutils}/bin/mkdir -p ${home}/.local/share/atuin-store/tmpfs

    case "$1" in
      restore)
      echo "Restoring atuin tmpfs";
      ${pkgs.rsync}/bin/rsync -av \
        /home/happens/.local/share/atuin-store/tmpfs/ \
        /home/happens/.local/share/atuin/
      ;;
      persist)
      echo "Persisting atuin tmpfs"
      ${pkgs.rsync}/bin/rsync -av --delete --recursive --force \
        /home/happens/.local/share/atuin/ \
        /home/happens/.local/share/atuin-store/tmpfs/
      ;;
    esac
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
      enableAutosuggestions = true;
      enableCompletion = true;
      enableVteIntegration = true;

      initExtra = "source $HOME/.config/zsh/init.zsh";
    };
  };

  services = {
    kanshi.enable = true;
    easyeffects.enable = true;
  };

  home = {
    inherit stateVersion username;
    homeDirectory = home;

    packages = with pkgs; [
      cachix
      zip
      wget
      git
      difftastic
      delta
      unzip
      file
      bat
      eza
      ripgrep
      ncdu
      btop
      curl
      xh
      lazygit
      yq
      jq
      fzf
      fd
      killall
      tokei
      kitty
      tmux
      wezterm-custom
      atuin-custom
      zoxide
      starship
      direnv
      google-chrome
      firefox-bin
      bitwarden
      tdesktop
      webcord
      signal-desktop
      element-desktop
      easyeffects
      obsidian
      gimp
      vimiv-qt
      nvd
      tealdeer
      gammastep
      spotify
      krita
      restic
      vlc
      node2nix
      just
      gcc
      rustup
      zig
      yarn
      go
      gopls
      gotools
      revive
      dive
      wofi
      mako
      notify-desktop
      eww-wayland
      hyprpicker
      grimblast
      python3
      gnumake
      pkgs-nodejs_19.docker-compose
      pkgs-nodejs_19.steam-run
      pkgs-nodejs_19.nodejs_19
      nodejs_21.pkgs.eslint_d
      nodejs_21.pkgs.vscode-langservers-extracted
      nodejs_21.pkgs.bash-language-server
      nodejs_21.pkgs.yaml-language-server
      nodejs_21.pkgs.graphql-language-service-cli
      nodejs_21.pkgs.typescript-language-server
      font-manager
      sumneko-lua-language-server
      stylua
      selene
      zls
      shellcheck
      shfmt
      nil
      alejandra
      llvmPackages_latest.libclang
      taplo
      awscli2
      terraform
      kubectl
      k9s
      kubernetes-helm
      packer
      tree-sitter
      neovim
      customPackages.neovim-nightly
      xdg-utils
      linuxPackages_latest.perf
      hyperfine
      yazi
      discord
      glab

      # Really dirty hack since gnome-terminal is hardcoded for gtk-launch
      (writeShellScriptBin "gnome-terminal" "shift; ${wezterm-custom}/bin/wezterm -e \"$@\"")
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      SDL_VIDEODRIVER = "wayland";
      XCURSOR_SIZE = "24";

      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };

    file = {
      ".gitconfig".source = "${dotfiles}/git/gitconfig";
      ".gitconfig-garage".source = "${dotfiles}/git/gitconfig-garage";
      ".gitconfig-opencreek".source = "${dotfiles}/git/gitconfig-opencreek";
      ".ssh/config".source = "${dotfiles}/ssh/config";
    };

    pointerCursor = {
      gtk.enable = true;
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    activation = {
      installNpmPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
        export NPM_CONFIG_PREFIX="$HOME/.npm-packages"
        export NODE_PATH="$HOME/.npm-packages/lib/node_modules"
        ${pkgs-nodejs_19.nodejs_19}/bin/npm i -g ${lib.strings.concatStringsSep " " globalNpmPackages}
      '';
    };
  };

  systemd.user.services = {
    polkit-agent = {
      Unit.Description = "Polkit Agent";
      Install.WantedBy = ["graphical-session.target"];

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
        Restart = "always";
      };
    };

    atuin-tmpfs-sync = {
      Unit.Description = "Atuin tmpfs sync";
      Install.WantedBy = ["default.target"];

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${atuin-tmpfs} restore";
        ExecStop = "${atuin-tmpfs} persist";
      };
    };
  };

  xdg = {
    configFile = {
      "host".source = hostDotfiles;

      "bat".source = "${dotfiles}/bat";
      "nvim".source = "${dotfiles}/nvim";
      "nix".source = "${dotfiles}/nix";
      "zsh".source = "${dotfiles}/zsh";
      "waybar".source = "${dotfiles}/waybar";
      "wezterm".source = "${dotfiles}/wezterm";
      "kitty".source = "${dotfiles}/kitty";
      "starship.toml".source = "${dotfiles}/starship/starship.toml";
      "hypr".source = "${dotfiles}/hypr";
      "tealdeer".source = "${dotfiles}/tealdeer";
      "mako".source = "${dotfiles}/mako";
      "wofi".source = "${dotfiles}/wofi";
      "atuin".source = "${dotfiles}/atuin";
      "lazygit/config.yml".source = "${dotfiles}/lazygit/config.yml";
      "btop/btop.conf".source = "${dotfiles}/btop/btop.conf";
      "btop/themes".source = "${dotfiles}/btop/themes";
    };

    systemDirs.data = [gsettingsDatadir];
  };

  dconf.settings = {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:none";
    };
  };

  gtk = {
    enable = true;
    theme.name = "Orchis-Dark";
    cursorTheme.name = "Bibata-Modern-Classic";
    iconTheme.name = "Qogir-dark";

    gtk3.extraConfig = {
      gtk-decoration-layout = ":menu";
    };

    gtk4.extraConfig = {
      gtk-decoration-layout = ":menu";
    };
  };
}
