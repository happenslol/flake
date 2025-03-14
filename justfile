set shell := ["zsh", "-c"]

alias p := push
alias f := format
alias a := apply

default:
  just --list

# Apply the current flake configuration
@apply:
  git add .
  sudo nixos-rebuild switch --flake ~/.flake#

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
