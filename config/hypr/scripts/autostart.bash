#!/usr/bin/env bash

setup-hyprland-environment &
systemctl --user import-environment

# Set wallpaper
if ! swww query; then swww init; fi
swww clear 2d2e2f
