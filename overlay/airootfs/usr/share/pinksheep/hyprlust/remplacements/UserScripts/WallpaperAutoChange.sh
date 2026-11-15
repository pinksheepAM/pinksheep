#!/usr/bin/env bash
# PinkSheep : change de fond toutes les N minutes (30 par défaut).  Usage : WallpaperAutoChange.sh [minutes]
minutes="${1:-30}"
while true; do
    sleep "$((minutes * 60))"
    pinksheep-fond --aleatoire
done
