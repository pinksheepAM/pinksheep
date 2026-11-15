#!/usr/bin/env bash
# PinkSheep : relance la barre et les notifications
pkill -x rofi 2>/dev/null
pkill -x waybar 2>/dev/null; sleep 0.3
waybar >/dev/null 2>&1 & disown
swaync-client -R >/dev/null 2>&1; swaync-client -rs >/dev/null 2>&1
exit 0
