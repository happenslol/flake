{ config, pkgs, ... }:

{
  home.username = "happens";
  home.homeDirectory = "/home/happens";
  home.stateVersion = "22.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    tmux yq curl xh neovim fzf gcc unzip
    bat exa ripgrep ncdu zoxide starship
    wl-clipboard
    kitty
    waybar
    bitwarden
    rustup
    google-chrome firefox
    tdesktop discord signal-desktop
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
    ".config/nvim" = {
      recursive = true;
      source = ./config/nvim;
    };
  };
}
