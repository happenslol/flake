#!/usr/bin/env bash
mkdir -p ~/screenshots

timestamp="$(date +"%Y%m%d-%H%M%S-%N")"
grimblast --notify copysave "$1" ~/screenshots/"$timestamp".png
