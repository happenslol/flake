#!/usr/bin/env bash

setup-hyprland-environment &

# Clear primary selection
wl-paste -p --watch wl-copy -pc &

# Start gammastep
wlsunset -l 50.1 -L 8.7 -t 4200 -T 6500
