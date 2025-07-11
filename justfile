set shell := ["zsh", "-c"]

alias p := push
alias d := develop
alias f := format
alias a := apply
alias npmi := npm-install

default:
  just --list

# Apply the current flake configuration
@apply:
  git add .
  sudo nixos-rebuild switch --flake ~/.flake#

[working-directory: "npm-global"]
npm-install *ARGS:
  #!/usr/bin/env zsh
  npm i --package-lock-only {{ARGS}}
  hash=$(prefetch-npm-deps package-lock.json)
  escaped=$(printf '%s\n' "$hash" | sed -e 's/[\/&]/\\&/g')
  sed -i "s|npmDepsHash = \".*\";|npmDepsHash = \"$escaped\";|" default.nix

# Build the current flake configuration
@build:
  nixos-rebuild build --flake ~/.flake#

@push message="Update flake":
  git add .
  git commit -m "{{message}}"
  git push

# Format all files
format: format-nix format-nvim

@format-nix:
  alejandra -q ./**/*.nix

# Format nvim configuration
@format-nvim:
  stylua -f config/nvim/stylua.toml ./config/nvim/**/*.lua

# Use a global devshell
[no-cd]
@develop shell="gui":
  nix develop ~/.flake#{{shell}} --command zsh
