#!/usr/bin/env bash
# PinkSheep — correctifs système appliqués par « pinksheep-maj » (lancé en root).
# Chaque correctif doit pouvoir être relancé sans risque.

# 2026-11 : DNS en panne après l'installation (Wi-Fi connecté mais aucun site)
if ! systemctl is-enabled systemd-resolved.service >/dev/null 2>&1; then
    systemctl enable --now systemd-resolved.service && echo "   -> DNS réparé (systemd-resolved activé)"
fi
