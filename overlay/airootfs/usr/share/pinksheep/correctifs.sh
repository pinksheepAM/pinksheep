#!/usr/bin/env bash
# PinkSheep — correctifs système appliqués par « pinksheep-maj » (lancé en root).
# Chaque correctif doit pouvoir être relancé sans risque.

# 2026-11 : DNS en panne après l'installation (Wi-Fi connecté mais aucun site)
if ! systemctl is-enabled systemd-resolved.service >/dev/null 2>&1; then
    systemctl enable --now systemd-resolved.service && echo "   -> DNS réparé (systemd-resolved activé)"
fi

# 2026-11 (1.1) : Bluetooth sans « A2DP duplex » (enceintes connectées mais muettes)
cible=/etc/wireplumber/wireplumber.conf.d/51-pinksheep-bluetooth.conf
if ! cmp -s /usr/share/pinksheep/systeme/wireplumber/51-pinksheep-bluetooth.conf "$cible"; then
    install -Dm644 /usr/share/pinksheep/systeme/wireplumber/51-pinksheep-bluetooth.conf "$cible"
    echo "   -> Bluetooth : réglage audio installé (actif après redémarrage)"
fi

# 2026-11 (1.1) : pare-feu activé (connexions entrantes refusées)
if command -v ufw >/dev/null && ! ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw --force enable >/dev/null && systemctl enable ufw.service >/dev/null 2>&1 && \
        echo "   -> Pare-feu activé (rien n'entre sans y être invité)"
fi

# 2026-11 (1.1) : catalogue Flathub pour Discover
if command -v flatpak >/dev/null && ! flatpak remotes --system 2>/dev/null | grep -q '^flathub'; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo && \
        echo "   -> Flathub ajouté (applis disponibles dans Discover)"
fi

# 2026-11 (1.1) : ménage décidé au bilan (Okular reste le lecteur PDF)
a_retirer=()
for p in zathura-pdf-mupdf zathura newsboat; do
    pacman -Q "$p" >/dev/null 2>&1 && a_retirer+=("$p")
done
if ((${#a_retirer[@]})) && pacman -Q okular >/dev/null 2>&1; then
    pacman -Rns --noconfirm "${a_retirer[@]}" >/dev/null 2>&1 && \
        echo "   -> Ménage : ${a_retirer[*]} retiré(s) (Okular reste le lecteur PDF)"
fi
