{ config, pkgs, ... }:

let
  typescript-language-server-fixed = pkgs.symlinkJoin {
    name = "typescript-language-server";
    paths = [ pkgs.nodePackages_latest.typescript-language-server ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/typescript-language-server \
        --add-flags --tsserver-path=${pkgs.nodePackages_latest.typescript}/lib/node_modules/typescript/lib/
    '';
  };
in
{
  home.username = "happens";
  home.homeDirectory = "/home/happens";
  home.stateVersion = "22.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    tmux yq curl xh neovim fzf gcc unzip file
    bat exa ripgrep ncdu zoxide starship bottom
    kitty bitwarden rustup
    google-chrome firefox
    tdesktop discord signal-desktop
    wofi mako notify-desktop

    # Node and tooling
    nodejs yarn

    # LSP servers for Neovim
    nodePackages_latest.prettier_d_slim
    nodePackages_latest.eslint_d
    typescript-language-server-fixed
    nodePackages_latest.vscode-json-languageserver-bin
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
    ".config/nvim/.luarc.json".source = ./config/nvim/.luarc.json;
    ".config/nvim/lua".source = ./config/nvim/lua;
  };
}
