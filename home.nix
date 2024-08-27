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

  customPackages = {
    neovim-nightly = let
      neovim-nightly = inputs.neovim-nightly-overlay.packages.${system}.neovim;
    in (pkgs.writeShellScriptBin "nvim-nightly" "exec -a $0 ${neovim-nightly}/bin/nvim $@");
  };

  atuin-custom = inputs.atuin.packages."${system}".default;

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
      autosuggestion.enable = true;
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

    sessionVariables = {
      GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };

    file = {
      ".gitconfig".source = "${dotfiles}/git/gitconfig";
      ".gitconfig-garage".source = "${dotfiles}/git/gitconfig-garage";
      ".gitconfig-opencreek".source = "${dotfiles}/git/gitconfig-opencreek";
      ".ssh/config".source = "${dotfiles}/ssh/config";
      ".tmux.conf".source = "${dotfiles}/tmux/tmux.conf";
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
      Unit.Description = "Polkit Agent";
      Install.WantedBy = ["graphical-session.target"];

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1";
        Restart = "always";
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
      "dash2".source = "${dotfiles}/dash2";
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

  home.packages = with pkgs; [
    # Really dirty hack since gnome-terminal is hardcoded for gtk-launch
    (writeShellScriptBin "gnome-terminal" "shift; ${kitty}/bin/kitty -e \"$@\"")

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
    nvd
    tealdeer
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
    grimblast
    python3
    gnumake
    wlsunset

    docker-compose
    steam-run
    nodejs_22

    nodejs_22.pkgs.eslint_d
    nodejs_22.pkgs.vscode-langservers-extracted
    nodejs_22.pkgs.bash-language-server
    nodejs_22.pkgs.yaml-language-server
    nodejs_22.pkgs.graphql-language-service-cli
    nodejs_22.pkgs.typescript-language-server
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
    imagemagick
    android-studio
    spacedrive
    slack
    swaylock
    libreoffice
    bun
    bc
    postgresql_16
    playerctl
    nix-index
    bluetuith
    ollama
    (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
      app-engine-go
    ]))
    google-cloud-sql-proxy
    jless
    mosh
    libnotify
    distrobox
    (vesktop.override {
      withSystemVencord = false;
      withMiddleClickScroll = true;
    })
    zed-editor
    obs-studio
    bruno
    delve
    gofumpt
    halloy
    konversation
    kooha
  ];
}
