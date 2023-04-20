#!/usr/bin/env bash

setup-hyprland-environment &

# Set wallpaper
if ! swww query; then swww init; fi
swww clear 2d2e2f

# Clear primary selection
wl-paste -p --watch wl-copy -pc &

# Start gammastep
gammastep -l 50.105492:8.7592655 -t 6500K:4200K &

# Clear turbod daemon on startup
rm /tmp/turbod/**/*
