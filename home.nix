{ config, pkgs, stateVersion, hostname, customNodePackages, ... }:

let
  fixed-typescript-language-server =
    import ./fixes/typescript-language-server.nix pkgs;
in {
  programs.home-manager.enable = true;

  services = {
    kanshi.enable = true;
    easyeffects.enable = true;
  };

  programs.neovim = {
    enable = true; 
    plugins = [pkgs.vimPlugins.nvim-treesitter.withAllGrammars];
    extraConfig = ''lua require "config"'';
  };

  home = {
    inherit stateVersion;
    username = "happens";
    homeDirectory = "/home/happens";

    packages = with pkgs; [
      wget git unzip file
      bat exa ripgrep ncdu bottom curl xh yq fzf tokei
      kitty tmux zoxide starship direnv
      google-chrome firefox-wayland bitwarden
      tdesktop discord signal-desktop
      easyeffects flameshot
      obsidian gimp vimiv-qt
      nvd

      steam-run
      docker-compose
      gcc
      rustup
      nodejs yarn
      go gopls gotools revive

      wofi mako notify-desktop

      customNodePackages."@fsouza/prettierd"

      nodePackages_latest.eslint_d
      fixed-typescript-language-server
      nodePackages_latest.vscode-json-languageserver-bin
      sumneko-lua-language-server
      rust-analyzer
      awscli2
    ];

    sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      MOZ_USE_XINPUT2 = 1;
      SDL_VIDEODRIVER = "wayland";
    };

    file = {
      ".zshrc".source = ./config/zshrc;
      ".config/zsh".source = ./config/zsh;
      ".config/nvim/lua".source = ./config/nvim;
      ".config/waybar".source = ./config/waybar;
      ".config/kitty".source = ./config/kitty;
      ".config/tmux".source = ./config/tmux;
      ".config/starship.toml".source = ./config/starship/starship.toml;

      ".gitconfig".source = ./config/git/gitconfig;
      ".gitconfig-garage".source = ./config/git/gitconfig-garage;
      ".gitconfig-opencreek".source = ./config/git/gitconfig-opencreek;

      ".config/sway/config".source = ./config/sway/config;
      ".config/sway/${hostname}.config".source = (./. + "/hosts/${hostname}/config/sway/config");
    };
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
