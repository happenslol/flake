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

  cursorTheme = {
    package = pkgs.yaru-theme;
    name = "Yaru";
  };

  makeNodePackage = {
    input,
    binary,
    translator,
  }: let
    npmPackageOutputs = inputs.dream2nix.lib.makeFlakeOutputs {
      systems = [system];
      config.projectRoot = ./.;
      source = inputs.prettierd;
      projects = {
        prettier = {
          name = "prettierd";
          subsystem = "nodejs";
          translator =
            if translator != null
            then translator
            else "package-lock";
        };
      };
    };

    npmPackages = npmPackageOutputs.packages.${system};
  in
    pkgs.writeShellScriptBin binary "exec -a $0 ${npmPackages.prettierd}/bin/${binary} $@";

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
in {
  programs.home-manager.enable = true;

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
      unzip
      file
      bat
      exa
      ripgrep
      ncdu
      bottom
      curl
      xh
      yq
      jq
      fzf
      tokei
      kitty
      wezterm
      tmux
      zoxide
      starship
      direnv
      google-chrome
      firefox-wayland
      bitwarden
      tdesktop
      discord
      signal-desktop
      element-desktop-wayland
      easyeffects
      flameshot
      obsidian
      gimp
      vimiv-qt
      nvd

      just
      steam-run
      docker-compose
      gcc
      rustup
      nodejs
      yarn
      go
      gopls
      gotools
      revive

      wofi
      mako
      notify-desktop
      eww-wayland

      nodePackages_latest.pnpm
      nodePackages_latest.eslint_d
      nodePackages_latest.vscode-langservers-extracted
      nodePackages_latest.bash-language-server
      nodePackages_latest.yaml-language-server
      nodePackages_latest.graphql-language-service-cli
      customPackages.fixed-typescript-language-server
      sumneko-lua-language-server
      stylua
      selene
      rust-analyzer
      shellcheck
      shfmt
      nil
      alejandra

      awscli2
      terraform
      kubectl
      kubernetes-helm
      packer

      neovim
      customPackages.neovim-nightly

      handlr
      (writeShellScriptBin "xdg-open" "${handlr}/bin/handlr open $@")

      customPackages.prettierd
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = 1;
      MOZ_ENABLE_WAYLAND = 1;
      MOZ_USE_XINPUT2 = 1;
      SDL_VIDEODRIVER = "wayland";
      XCURSOR_THEME = cursorTheme.name;
      XCURSOR_SIZE = "24";
    };

    file = {
      ".zshrc".source = "${dotfiles}/zshrc";
      ".gitconfig".source = "${dotfiles}/git/gitconfig";
      ".gitconfig-garage".source = "${dotfiles}/git/gitconfig-garage";
      ".gitconfig-opencreek".source = "${dotfiles}/git/gitconfig-opencreek";
    };

    pointerCursor = {
      inherit (cursorTheme) package name;
      gtk.enable = true;
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

  xdg.configFile = {
    "host".source = hostDotfiles;

    "nvim".source = "${dotfiles}/nvim";
    "nix".source = "${dotfiles}/nix";
    "zsh".source = "${dotfiles}/zsh";
    "waybar".source = "${dotfiles}/waybar";
    "wezterm".source = "${dotfiles}/wezterm";
    "kitty".source = "${dotfiles}/kitty";
    "tmux".source = "${dotfiles}/tmux";
    "starship.toml".source = "${dotfiles}/starship/starship.toml";
    "sway".source = "${dotfiles}/sway";
    "hypr".source = "${dotfiles}/hypr";
  };

  gtk = {
    inherit cursorTheme;

    enable = true;
    theme = {
      package = pkgs.vimix-gtk-themes;
      name = "vimix-dark-doder";
    };
    iconTheme = {
      package = pkgs.vimix-icon-theme;
      name = "Vimix Doder dark";
    };
  };
}
