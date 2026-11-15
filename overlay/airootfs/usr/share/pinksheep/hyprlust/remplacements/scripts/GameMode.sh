#!/usr/bin/env bash
# PinkSheep (Hyprland 0.57, config Lua) : mode jeu = pas d'animations, de flou, d'ombres ni d'espaces
etat="${XDG_STATE_HOME:-$HOME/.local/state}/pinksheep/mode-jeu"
mkdir -p "$(dirname "$etat")"
if [[ -e "$etat" ]]; then
    rm -f "$etat"
    hyprctl reload >/dev/null
    notify-send -a PinkSheep "Mode jeu" "Désactivé : effets rétablis"
else
    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = { blur = { enabled = false }, shadow = { enabled = false }, rounding = 0 },
        general    = { gaps_in = 0, gaps_out = 0, border_size = 1 },
    })' >/dev/null
    touch "$etat"
    notify-send -a PinkSheep "Mode jeu" "Activé : effets coupés pour plus de FPS"
fi
