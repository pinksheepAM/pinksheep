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

# 2026-11 (1.2) : thème PinkSheep pour le menu de démarrage (sauf si on a choisi le menu texte)
if [[ -f /etc/default/grub && ! -f /etc/pinksheep/grub-texte ]] && command -v grub-mkconfig >/dev/null; then
    if ! cmp -s /usr/share/pinksheep/grub/pinksheep/theme.txt /boot/grub/themes/pinksheep/theme.txt; then
        /usr/local/bin/pinksheep-grub --theme >/dev/null 2>&1 && \
            echo "   -> Menu de démarrage aux couleurs de PinkSheep (menu texte : sudo pinksheep-grub --texte)"
    fi
fi

# 2026-11 (1.1.3) : écran de chargement PinkSheep (Plymouth), sauf si on l'a désactivé
if command -v plymouth-set-default-theme >/dev/null && [[ ! -f /etc/pinksheep/chargement-off ]]; then
    if ! grep -Eq '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf 2>/dev/null \
       || ! diff -rq /usr/share/pinksheep/plymouth/pinksheep /usr/share/plymouth/themes/pinksheep >/dev/null 2>&1; then
        echo "   -> Écran de chargement : installation (une minute environ)…"
        if sortie="$(/usr/local/bin/pinksheep-chargement 2>&1)"; then
            echo "   -> Écran de chargement PinkSheep activé (désactiver : sudo pinksheep-chargement --off)"
        else
            echo "   -> Écran de chargement non activé :"; tail -n 3 <<<"$sortie" | sed 's/^/      /'
        fi
    fi
fi

# 2026-11 (1.1.5) : affichage à l'écran de Verr. Maj / Verr. Num (SwayOSD)
if [[ -f /usr/lib/systemd/system/swayosd-libinput-backend.service ]] && \
   ! systemctl is-enabled swayosd-libinput-backend.service >/dev/null 2>&1; then
    systemctl enable --now swayosd-libinput-backend.service >/dev/null 2>&1 && \
        echo "   -> Verr. Maj et Verr. Num s'affichent à l'écran quand tu appuies dessus"
fi

# 2026-11 (1.1.5) : instantané Timeshift avant chaque mise à jour
if command -v timeshift >/dev/null; then
    cible=/usr/share/libalpm/hooks/00-pinksheep-instantane.hook
    if ! cmp -s /usr/share/pinksheep/systeme/pacman/00-pinksheep-instantane.hook "$cible"; then
        install -Dm644 /usr/share/pinksheep/systeme/pacman/00-pinksheep-instantane.hook "$cible"
        [[ -f /etc/timeshift/timeshift.json ]] || /usr/local/bin/pinksheep-instantane --configurer >/dev/null
        echo "   -> Instantané du système avant chaque mise à jour (revenir en arrière : sudo timeshift --restore)"
    fi
fi

# 2026-11 (1.1.5) : Heroic Games Launcher (jeux Epic, GOG, Amazon), une seule fois :
# si tu le désinstalles, il ne revient pas
if command -v flatpak >/dev/null && [[ ! -f /etc/pinksheep/heroic-installe ]]; then
    echo "   -> Installation de Heroic Games Launcher (jeux Epic), quelques minutes…"
    if flatpak install -y --noninteractive --system flathub com.heroicgameslauncher.hgl >/dev/null 2>&1; then
        mkdir -p /etc/pinksheep && touch /etc/pinksheep/heroic-installe
        echo "   -> Heroic installé (dans le lanceur : « Heroic Games Launcher »)"
    else
        echo "   -> Heroic n'a pas pu être installé (connexion ?) : ce sera retenté à la prochaine mise à jour"
    fi
fi

# 2026-11 (1.1.6) : les crochets pacman PinkSheep passent de /etc/pacman.d/hooks
# (lu aussi quand on construit un chroot ou une ISO depuis ce PC, où ils échouaient)
# à /usr/share/libalpm/hooks (propre à ce système seulement)
for c in 00-pinksheep-instantane.hook pinksheep-grub-silencieux.hook; do
    if [[ -f /etc/pacman.d/hooks/$c ]]; then
        [[ -f /usr/share/libalpm/hooks/$c ]] || install -Dm644 "/etc/pacman.d/hooks/$c" "/usr/share/libalpm/hooks/$c"
        rm -f "/etc/pacman.d/hooks/$c"
    fi
done
