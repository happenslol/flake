{
  config, pkgs, stateVersion, hostname, customNodePackages,
  inputs, system, username, ...
}:

let
  fixed-typescript-language-server =
    import ./fixes/typescript-language-server.nix pkgs;
  neovim-nightly =
    inputs.neovim-nightly-overlay.packages.${system}.neovim;
  dotfiles =
    config.lib.file.mkOutOfStoreSymlink "/home/${username}/.flake/config";
  hostDotfiles =
    config.lib.file.mkOutOfStoreSymlink "/home/${username}/.flake/hosts/${hostname}/config";
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
      wget git difftastic unzip file
      bat exa ripgrep ncdu bottom curl xh yq jq fzf tokei
      kitty wezterm tmux zoxide starship direnv
      google-chrome firefox-wayland bitwarden
      tdesktop discord signal-desktop element-desktop-wayland
      easyeffects flameshot
      obsidian gimp vimiv-qt
      nvd

      just
      steam-run
      docker-compose
      gcc
      rustup
      nodejs yarn
      go gopls gotools revive

      wofi mako notify-desktop eww-wayland

      nodePackages_latest.pnpm
      nodePackages_latest.eslint_d
      customNodePackages."@fsouza/prettierd"
      nodePackages_latest.vscode-langservers-extracted
      nodePackages_latest.bash-language-server
      nodePackages_latest.yaml-language-server
      nodePackages_latest.graphql-language-service-cli
      fixed-typescript-language-server
      sumneko-lua-language-server stylua selene
      rust-analyzer
      shellcheck shfmt
      nil alejandra
      xdg-utils handlr

      awscli2
      terraform kubectl kubernetes-helm packer

      neovim
      (writeShellScriptBin "nvim-nightly" "exec -a $0 ${neovim-nightly}/bin/nvim $@")
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = 1;
      MOZ_ENABLE_WAYLAND = 1;
      MOZ_USE_XINPUT2 = 1;
      SDL_VIDEODRIVER = "wayland";
    };

    file = {
      ".zshrc".source = "${dotfiles}/zshrc";

      ".gitconfig".source = "${dotfiles}/git/gitconfig";
      ".gitconfig-garage".source = "${dotfiles}/git/gitconfig-garage";
      ".gitconfig-opencreek".source = "${dotfiles}/git/gitconfig-opencreek";
    };
  };

  xdg.configFile = {
    "nvim".source = "${dotfiles}/nvim";

    "zsh".source = "${dotfiles}/zsh";
    "waybar".source = "${dotfiles}/waybar";
    "wezterm".source = "${dotfiles}/wezterm";
    "kitty".source = "${dotfiles}/kitty";
    "tmux".source = "${dotfiles}/tmux";
    "starship.toml".source = "${dotfiles}/starship/starship.toml";

    "sway/config".source = "${dotfiles}/sway/config";
    "sway/${hostname}.config".source = "/${hostDotfiles}/sway/config";
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.vimix-gtk-themes;
      name = "vimix-dark-doder";
    };
    cursorTheme = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors";
    };
    iconTheme = {
      package = pkgs.vimix-icon-theme;
      name = "Vimix Doder dark";
    };
  };
}
