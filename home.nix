{ config, pkgs, stateVersion, hostname, ... }:

let
  fixed-typescript-language-server =
    import ./fixes/typescript-language-server.nix pkgs;
in {
  programs.home-manager.enable = true;

  home = {
    inherit stateVersion;
    username = "happens";
    homeDirectory = "/home/happens";

    packages = with pkgs; [
      neovim wget git unzip file
      bat exa ripgrep ncdu bottom curl xh yq fzf
      kitty tmux zoxide starship direnv
      google-chrome firefox bitwarden
      tdesktop discord signal-desktop
      easyeffects
      flameshot
      xfce.thunar
      obsidian

      gcc
      rustup
      nodejs yarn

      wofi mako notify-desktop

      # LSP servers for Neovim
      nodePackages_latest.prettier_d_slim
      nodePackages_latest.eslint_d
      fixed-typescript-language-server
      nodePackages_latest.vscode-json-languageserver-bin
      sumneko-lua-language-server
      rust-analyzer
    ];

    file = {
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

      ".gitconfig".text = ''
        [init]
          defaultBranch = main

        [user]
          name = Hilmar Wiegand
          email = me@hwgnd.de

        [core]
          sshCommand = "ssh -i ~/.ssh/${hostname}.personal.id_ed25519"

        [includeIf "gitdir:~/opencreek/"]
          path = ~/.gitconfig-opencreek
        [includeIf "gitdir:~/garage/"]
          path = ~/.gitconfig-garage
      '';
      ".gitconfig-garage".text = ''
        [user]
          email = hilmar@garage51.de
        [core]
          sshCommand = "ssh -i ~/.ssh/${hostname}.garage51.id_ed25519"
      '';
      ".gitconfig-opencreek".text = ''
        [user]
          email = hilmar@opencreek.tech
        [core]
          sshCommand = "ssh -i ~/.ssh/${hostname}.opencreek.id_ed25519"
      '';
    };
  };

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
}
