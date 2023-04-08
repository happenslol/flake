set shell := ["zsh", "-c"]

default:
  just --list

# Apply the current flake configuration
@apply:
  sudo nixos-rebuild switch --flake ~/.flake#

# Build the current flake configuration
@build:
  sudo nixos-rebuild build --flake ~/.flake#

@push message="Update flake":
  git add .
  git commit -m "{{message}}"
  git push

# Format all files
format: format-nvim format-wezterm

# Format nvim configuration
@format-nvim:
  stylua -v -f config/nvim/stylua.toml ./config/nvim/**/*.lua

# Format wezterm configuration
@format-wezterm:
  stylua -f config/wezterm/stylua.toml ./config/wezterm/**/*.lua
