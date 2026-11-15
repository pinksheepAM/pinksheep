#!/usr/bin/env bash
# PinkSheep (Hyprland 0.57, config Lua) : bascule entre les dispositions master et dwindle
etat="${XDG_STATE_HOME:-$HOME/.local/state}/pinksheep/disposition-dwindle"
mkdir -p "$(dirname "$etat")"
if [[ -e "$etat" ]]; then
    hyprctl eval 'hl.config({ general = { layout = "master" } })' >/dev/null
    rm -f "$etat"
    notify-send -a PinkSheep -u low "Disposition" "Master (une grande fenêtre + une pile)"
else
    hyprctl eval 'hl.config({ general = { layout = "dwindle" } })' >/dev/null
    touch "$etat"
    notify-send -a PinkSheep -u low "Disposition" "Dwindle (découpe en spirale)"
fi
