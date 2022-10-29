{ config, pkgs, ... }:

{
  home.username = "happens";
  home.homeDirectory = "/home/happens";
  home.stateVersion = "22.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    tmux yq curl xh neovim fzf gcc unzip file
    bat exa ripgrep ncdu zoxide starship
    kitty bitwarden rustup
    google-chrome firefox
    tdesktop discord signal-desktop

    # Node and tooling
    nodejs yarn

    # LSP servers for Neovim
    nodePackages_latest.prettier_d_slim
    nodePackages_latest.eslint_d
    nodePackages_latest.typescript-language-server
    sumneko-lua-language-server
    rust-analyzer
  ];

  gtk = {
    enable = true;
    theme = {
      package = pkgs.vimix-gtk-themes;
      name = "vimix-dark-doder";
    };
    cursorTheme = {
      package = pkgs.quintom-cursor-theme;
      name = "Quintom_Ink";
    };
    iconTheme = {
      package = pkgs.vimix-icon-theme;
      name = "Vimix Doder dark";
    };
  };

  home.file = {
    ".zshrc".source = ./config/.zshrc;
    ".config/zsh".source = ./config/zsh;
    ".config/sway".source = ./config/sway;
    ".config/waybar".source = ./config/waybar;
    ".config/kitty".source = ./config/kitty;
    ".config/tmux".source = ./config/tmux;
    ".config/starship.toml".source = ./config/starship/starship.toml;
    ".config/nvim/init.lua".source = ./config/nvim/init.lua;
    ".config/nvim/lua".source = ./config/nvim/lua;
  };
}
