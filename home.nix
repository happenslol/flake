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
  dotfiles =
    config.lib.file.mkOutOfStoreSymlink "/home/${username}/.flake/config";
  hostDotfiles =
    config.lib.file.mkOutOfStoreSymlink "/home/${username}/.flake/hosts/${hostname}/config";

  makeNodePackage = args @ {
    input,
    binary,
    ...
  }: let
    npmPackageOutputs = inputs.dream2nix.lib.makeFlakeOutputs {
      systems = [system];
      config.projectRoot = ./.;
      source = inputs.prettierd;
      projects = {
        "${binary}" = {
          name = binary;
          subsystem = "nodejs";
          translator = args.translator or "";
        };
      };
    };

    npmPackages = npmPackageOutputs.packages.${system};
  in
    pkgs.writeShellScriptBin binary "exec -a $0 ${npmPackages."${binary}"}/bin/${binary} $@";

  customPackages = {
    fixed-typescript-language-server =
      import ./fixes/typescript-language-server.nix pkgs;

    neovim-nightly = let
      neovim-nightly = inputs.neovim-nightly-overlay.packages.${system}.neovim;
    in (pkgs.writeShellScriptBin "nvim-nightly" "exec -a $0 ${neovim-nightly}/bin/nvim $@");

    prettierd = makeNodePackage {
      input = inputs.prettierd;
      binary = "prettierd";
      translator = "yarn-lock";
    };
  };

  wezterm-main = inputs.wezterm.packages."${system}".default;

  gsettingsSchemas = pkgs.gsettings-desktop-schemas;
  gsettingsDatadir = "${gsettingsSchemas}/share/gsettings-schemas/${gsettingsSchemas.name}";
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

      initExtra = ''source $HOME/.config/zsh/init.zsh'';
    };
  };

  services = {
    kanshi.enable = true;
    easyeffects.enable = true;
  };

  home = {
    inherit stateVersion username;
    homeDirectory = "/home/${username}";

    packages = with pkgs; [
      cachix
      wget
      git
      difftastic
      delta
      unzip
      file
      bat
      exa
      ripgrep
      ncdu
      bottom
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
      wezterm-main
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

      just
      steam-run
      docker-compose
      gcc
      rustup
      nodejs_19
      yarn
      go
      gopls
      gotools
      revive

      wofi
      mako
      notify-desktop
      eww-wayland
      hyprpicker
      grimblast

      nodejs_19.pkgs.pnpm
      nodejs_19.pkgs.eslint_d
      nodejs_19.pkgs.vscode-langservers-extracted
      nodejs_19.pkgs.bash-language-server
      nodejs_19.pkgs.yaml-language-server
      nodejs_19.pkgs.graphql-language-service-cli

      customPackages.fixed-typescript-language-server
      customPackages.prettierd
      sumneko-lua-language-server
      stylua
      selene
      rust-analyzer
      shellcheck
      shfmt
      nil
      alejandra
      llvmPackages_latest.libclang
      taplo

      awscli2
      terraform
      kubectl
      kubernetes-helm
      packer

      tree-sitter
      neovim
      customPackages.neovim-nightly

      handlr
      (writeShellScriptBin "xdg-open" "${handlr}/bin/handlr open $@")

      # Really dirty hack since gnome-terminal is hardcoded for gtk-launch
      (writeShellScriptBin "gnome-terminal" "shift; ${wezterm-main}/bin/wezterm -e \"$@\"")
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      SDL_VIDEODRIVER = "wayland";
      XCURSOR_SIZE = "24";
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
  };

  systemd.user.services.polkit-agent = {
    Unit.Description = "Polkit Agent";
    Install.WantedBy = ["graphical-session.target"];

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
      Restart = "always";
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
      "tmux".source = "${dotfiles}/tmux";
      "starship.toml".source = "${dotfiles}/starship/starship.toml";
      "hypr".source = "${dotfiles}/hypr";
      "tealdeer".source = "${dotfiles}/tealdeer";
      "mako".source = "${dotfiles}/mako";
      "wofi".source = "${dotfiles}/wofi";

      "gtk-3.0/bookmarks".source = "${dotfiles}/gtk3/bookmarks";
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
