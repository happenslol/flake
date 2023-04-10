#!/usr/bin/env bash

systemctl --user import-environment
dbus-hyprland-environment &
configure-gtk &

# Set wallpaper
if ! swww query; then swww init; fi
swww clear 2d2e2f
