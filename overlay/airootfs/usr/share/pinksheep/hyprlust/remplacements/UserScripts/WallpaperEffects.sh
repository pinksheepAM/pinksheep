#!/usr/bin/env bash
# PinkSheep : les effets ImageMagick de Hyprlust ne sont pas repris ; on ouvre le sélecteur.
notify-send -a PinkSheep "Effets de fond d'écran" "Pas disponible dans PinkSheep : choisis plutôt un autre fond."
exec pinksheep-fond --choisir
