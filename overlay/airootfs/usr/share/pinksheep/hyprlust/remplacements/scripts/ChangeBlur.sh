#!/usr/bin/env bash
# PinkSheep (Hyprland 0.57, config Lua) : bascule flou fort / flou léger
etat="${XDG_STATE_HOME:-$HOME/.local/state}/pinksheep/flou-leger"
mkdir -p "$(dirname "$etat")"
if [[ -e "$etat" ]]; then
    hyprctl eval 'hl.config({ decoration = { blur = { size = 6, passes = 3 } } })' >/dev/null
    rm -f "$etat"
    notify-send -a PinkSheep -u low "Flou" "Flou normal"
else
    hyprctl eval 'hl.config({ decoration = { blur = { size = 2, passes = 1 } } })' >/dev/null
    touch "$etat"
    notify-send -a PinkSheep -u low "Flou" "Flou léger (moins gourmand)"
fi
