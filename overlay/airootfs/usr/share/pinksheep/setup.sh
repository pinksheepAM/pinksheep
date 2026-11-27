#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  PinkSheep — transforme une Arch Linux fraîchement installée  │
# │  en PinkSheep (Hyprland + thème + applis + pilotes).           │
# │                                                              │
# │  Lancé automatiquement par pinksheep-install (dans un chroot). │
# │  On peut aussi le relancer plus tard sur le système installé : │
# │      sudo pinksheep-setup                                     │
# │  Options :                                                   │
# │      --forcer-config   réécrit les configs des utilisateurs   │
# │                        (une sauvegarde est faite avant)       │
# ╰──────────────────────────────────────────────────────────────╯
set -uo pipefail

PINKSHEEP_DIR="${PINKSHEEP_DIR:-/usr/share/pinksheep}"
LOG=/var/log/pinksheep-setup.log
FORCER_CONFIG=0
[[ "${1:-}" == "--forcer-config" ]] && FORCER_CONFIG=1

ROSE=$'\e[38;2;255;126;182m'; LAV=$'\e[38;2;200;162;255m'; ROUGE=$'\e[31m'; RAZ=$'\e[0m'
etape()  { printf '\n%s:: %s%s\n' "$ROSE" "$*" "$RAZ"; }
info()   { printf '%s   -> %s%s\n' "$LAV" "$*" "$RAZ"; }
alerte() { printf '%s   [!] %s%s\n' "$ROUGE" "$*" "$RAZ"; }
echec()  { printf '\n%s[X] %s%s\n' "$ROUGE" "$*" "$RAZ"; printf 'Journal complet : %s\n' "$LOG"; exit 1; }

[[ $EUID -eq 0 ]] || echec "Ce script doit être lancé en root (sudo pinksheep-setup)."
[[ -f /etc/arch-release ]] || echec "Ce système n'est pas une Arch Linux."
[[ -d "$PINKSHEEP_DIR/skel" ]] || echec "Fichiers PinkSheep introuvables dans $PINKSHEEP_DIR."

exec > >(tee -a "$LOG") 2>&1
printf '\n===== PinkSheep setup — %s =====\n' "$(date)"

pac() { pacman --noconfirm --needed "$@"; }

# ────────────────────────────────────────────────────────────────
etape "Réglages de pacman (dépôt multilib pour Steam, téléchargements parallèles)"
if grep -q '^#\[multilib\]' /etc/pacman.conf; then
    sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    info "multilib activé"
fi
sed -i 's/^#Color/Color/; s/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
grep -q '^ILoveCandy' /etc/pacman.conf || sed -i '/^Color/a ILoveCandy' /etc/pacman.conf

etape "Mise à jour du système"
pacman --noconfirm -Syu || echec "La mise à jour a échoué (connexion internet ?)."

# ────────────────────────────────────────────────────────────────
etape "Détection de la carte graphique"
mkdir -p /etc/pinksheep
pac -S pciutils >/dev/null || alerte "pciutils non installé, détection approximative"
GPU_INFO="$(lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' || true)"
printf '%s\n' "$GPU_INFO" | sed 's/^/     /'

# Noyaux installés (linux, linux-lts, linux-zen…) -> paquets d'en-têtes pour DKMS
NOYAUX=()
for f in /usr/lib/modules/*/pkgbase; do
    [[ -f "$f" ]] && NOYAUX+=("$(cat "$f")")
done
ENTETES=()
for n in "${NOYAUX[@]}"; do ENTETES+=("${n}-headers"); done
[[ ${#ENTETES[@]} -eq 0 ]] && ENTETES=(linux-headers)

GPU_PAQUETS=()
GPU="autre"
if grep -qi 'nvidia' <<<"$GPU_INFO"; then
    # Turing (GTX 16xx, RTX 20xx) et plus récent : TU, GA, GH, AD, GB…
    if grep -Eq '\b(TU|GA|GH|AD|GB)[0-9]{3}' <<<"$GPU_INFO"; then
        GPU="nvidia"
        GPU_PAQUETS+=(nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings libva-nvidia-driver "${ENTETES[@]}")
        info "NVIDIA récente détectée -> pilote officiel (modules open)"
    else
        GPU="nvidia-ancienne"
        alerte "Carte NVIDIA plus ancienne que les GTX 16xx : le pilote officiel ne la gère plus."
        alerte "PinkSheep installe le pilote libre (nouveau). Pour le pilote propriétaire,"
        alerte "installe plus tard 'nvidia-580xx-dkms' depuis l'AUR."
        GPU_PAQUETS+=(mesa lib32-mesa vulkan-nouveau lib32-vulkan-nouveau)
    fi
fi
if grep -Eqi 'Advanced Micro Devices|AMD/ATI|\bRadeon\b' <<<"$GPU_INFO"; then
    [[ $GPU == autre ]] && GPU="amd"
    GPU_PAQUETS+=(mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon)
    info "Carte AMD détectée"
fi
if grep -q 'Intel Corporation' <<<"$GPU_INFO"; then
    [[ $GPU == autre ]] && GPU="intel"
    GPU_PAQUETS+=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver)
    info "Graphique Intel détecté"
fi
if grep -Eqi 'virtualbox|vmware|qxl|virtio' <<<"$GPU_INFO"; then
    GPU="vm"
    GPU_PAQUETS+=(mesa lib32-mesa virtualbox-guest-utils)
    alerte "Machine virtuelle détectée : Hyprland y tourne mal sans accélération 3D."
fi
[[ ${#GPU_PAQUETS[@]} -eq 0 ]] && GPU_PAQUETS+=(mesa lib32-mesa)
printf '%s\n' "$GPU" > /etc/pinksheep/gpu

etape "Installation des pilotes graphiques"
pac -S "${GPU_PAQUETS[@]}" || echec "Impossible d'installer les pilotes graphiques."

if [[ $GPU == nvidia ]]; then
    # Le hook "kms" chargerait nouveau au démarrage : on le retire (recommandé par le wiki Arch)
    if grep -Eq '^HOOKS=.*\bkms\b' /etc/mkinitcpio.conf; then
        sed -i -E '/^HOOKS=/ s/ kms\b//' /etc/mkinitcpio.conf
        info "hook kms retiré de mkinitcpio"
    fi
    # Garde la mémoire vidéo pendant la mise en veille (évite l'écran noir au réveil)
    printf 'options nvidia NVreg_PreserveVideoMemoryAllocations=1\n' > /etc/modprobe.d/pinksheep-nvidia.conf
    systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2>/dev/null || true
fi
if [[ $GPU == vm ]]; then
    systemctl enable vboxservice.service 2>/dev/null || true
fi

# ────────────────────────────────────────────────────────────────
etape "Installation du bureau PinkSheep"
ESSENTIELS=(); BONUS=()
while read -r cat paquet _; do
    [[ -z "${cat:-}" || "$cat" == \#* ]] && continue
    case "$cat" in
        essentiel) ESSENTIELS+=("$paquet") ;;
        bonus)     BONUS+=("$paquet") ;;
    esac
done < "$PINKSHEEP_DIR/paquets.txt"

pac -S "${ESSENTIELS[@]}" || echec "Un paquet essentiel n'a pas pu être installé (voir le message ci-dessus)."

etape "Installation des applis bonus"
DISPO=(); ABSENTS=()
for p in "${BONUS[@]}"; do
    if pacman -Si "$p" >/dev/null 2>&1; then DISPO+=("$p"); else ABSENTS+=("$p"); fi
done
[[ ${#ABSENTS[@]} -gt 0 ]] && alerte "Introuvables dans les dépôts (ignorés) : ${ABSENTS[*]}"
if ! pac -S "${DISPO[@]}"; then
    alerte "Installation groupée impossible, on essaie une par une…"
    for p in "${DISPO[@]}"; do pac -S "$p" || alerte "ignoré : $p"; done
fi

# ────────────────────────────────────────────────────────────────
etape "Outils et thème PinkSheep"
install -Dm755 -t /usr/local/bin "$PINKSHEEP_DIR"/bin/*
ln -sf "$PINKSHEEP_DIR/setup.sh" /usr/local/bin/pinksheep-setup
chmod 755 "$PINKSHEEP_DIR/setup.sh"

# Configs par défaut pour les futurs comptes (et zsh comme shell par défaut)
cp -rT "$PINKSHEEP_DIR/skel" /etc/skel
[[ -x /usr/bin/zsh ]] && sed -i 's#^SHELL=.*#SHELL=/usr/bin/zsh#' /etc/default/useradd 2>/dev/null

# Disposition clavier : reprise de la console (choisie dans archinstall)
KEYMAP="$(sed -n 's/^KEYMAP=//p' /etc/vconsole.conf 2>/dev/null | tr -d '"')"
XKB_LAYOUT="us"; XKB_VARIANT=""
case "$KEYMAP" in
    fr_CH*|ch-fr*)  XKB_LAYOUT="ch"; XKB_VARIANT="fr" ;;
    fr-bepo*)       XKB_LAYOUT="fr"; XKB_VARIANT="bepo" ;;
    fr*)            XKB_LAYOUT="fr" ;;
    be*)            XKB_LAYOUT="be" ;;
    ca*|cf*)        XKB_LAYOUT="ca"; XKB_VARIANT="fr" ;;
    de_CH*|ch*)     XKB_LAYOUT="ch" ;;
    de*)            XKB_LAYOUT="de" ;;
    uk*)            XKB_LAYOUT="gb" ;;
    us*|"")         XKB_LAYOUT="us" ;;
    *)              XKB_LAYOUT="${KEYMAP%%-*}" ;;
esac
info "clavier : console '${KEYMAP:-?}' -> Hyprland '$XKB_LAYOUT ${XKB_VARIANT}'"
ecrire_clavier() {
    cat > "$1" <<EOF
-- Disposition du clavier (générée à l'installation de PinkSheep).
-- Exemples : "fr" (AZERTY), "be" (belge), "ch" + variant "fr" (suisse romand), "us" (QWERTY)
hl.config({
    input = {
        kb_layout  = "$XKB_LAYOUT",
        kb_variant = "$XKB_VARIANT",
    },
})
EOF
}
ecrire_clavier /etc/skel/.config/hypr/clavier.lua

# Même disposition pour l'écran de connexion (SDDM tourne sous X11)
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
# Écrit par PinkSheep : disposition du clavier de l'écran de connexion
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "$XKB_LAYOUT"
        Option "XkbVariant" "$XKB_VARIANT"
EndSection
EOF

# Copie dans le dossier perso de chaque utilisateur
while IFS=: read -r nom _ uid _ _ home _; do
    (( uid >= 1000 && uid < 60000 )) || continue
    [[ -d "$home" ]] || continue
    if [[ -f "$home/.config/hypr/hyprland.lua" && $FORCER_CONFIG -eq 0 ]]; then
        info "$nom : config déjà présente, on n'y touche pas (option --forcer-config pour la remplacer)"
        continue
    fi
    if [[ -d "$home/.config" && $FORCER_CONFIG -eq 1 ]]; then
        sauvegarde="$home/.config.avant-pinksheep-$(date +%Y%m%d-%H%M%S)"
        cp -a "$home/.config" "$sauvegarde"
        info "$nom : ancienne config sauvegardée dans $sauvegarde"
        # perso.lua est à toi : on ne l'écrase jamais
        [[ -f "$home/.config/hypr/perso.lua" ]] && cp "$home/.config/hypr/perso.lua" /tmp/perso.lua.$$
    fi
    cp -rT "$PINKSHEEP_DIR/skel" "$home"
    [[ -f /tmp/perso.lua.$$ ]] && mv /tmp/perso.lua.$$ "$home/.config/hypr/perso.lua"
    ecrire_clavier "$home/.config/hypr/clavier.lua"
    chown -R "$nom:$(id -gn "$nom")" "$home"
    LANGUE="$(sed -n 's/^LANG=//p' /etc/locale.conf 2>/dev/null)"
    runuser -u "$nom" -- env LANG="$LANGUE" xdg-user-dirs-update 2>/dev/null || true
    # Chemins propres à l'utilisateur (dossier Musique en français ou en anglais…)
    MUSIQUE="$(runuser -u "$nom" -- env LANG="$LANGUE" xdg-user-dir MUSIC 2>/dev/null)"
    IMAGES="$(runuser -u "$nom" -- env LANG="$LANGUE" xdg-user-dir PICTURES 2>/dev/null)"
    sed -i "s#@HOME@#$home#g" "$home/.config/qt6ct/qt6ct.conf"
    sed -i "s#@MUSIQUE@#${MUSIQUE:-$home/Musique}#g" "$home/.config/mpd/mpd.conf"
    runuser -u "$nom" -- mkdir -p "${MUSIQUE:-$home/Musique}" "${IMAGES:-$home/Images}/FondsEcran" \
        "$home/.local/share/mpd/playlists" "$home/.local/state/mpd" "$home/.local/state/pinksheep"
    # Shell : zsh stylé
    if [[ -x /usr/bin/zsh ]]; then
        chsh -s /usr/bin/zsh "$nom" >/dev/null && info "$nom : shell par défaut -> zsh"
    fi
    info "$nom : config PinkSheep installée"
done < /etc/passwd

# ────────────────────────────────────────────────────────────────
etape "Écran de connexion et services"
mkdir -p /etc/sddm.conf.d /usr/share/sddm/themes
rm -rf /usr/share/sddm/themes/pinksheep
cp -a "$PINKSHEEP_DIR/sddm/pinksheep" /usr/share/sddm/themes/pinksheep
cat > /etc/sddm.conf.d/10-pinksheep.conf <<'EOF'
[General]
Numlock=on

[Theme]
# Thème PinkSheep (si jamais il ne se charge pas, SDDM revient à son thème intégré)
Current=pinksheep
CursorTheme=breeze_cursors
EOF

# NetworkManager gère le réseau ; on coupe les autres gestionnaires s'ils sont actifs
for s in systemd-networkd.service iwd.service; do
    if systemctl is-enabled "$s" >/dev/null 2>&1; then
        systemctl disable "$s" && info "$s désactivé (remplacé par NetworkManager)"
    fi
done
# Session de secours (rendu logiciel) sur l'écran de connexion
install -Dm644 "$PINKSHEEP_DIR/sessions/pinksheep-secours.desktop" \
    /usr/share/wayland-sessions/pinksheep-secours.desktop
if [[ $GPU == vm ]]; then
    alerte "Machine virtuelle : active l'accélération 3D (VirtualBox : Configuration > Affichage)"
    alerte "ou choisis la session « Hyprland (secours) » sur l'écran de connexion."
fi

systemctl enable sddm.service NetworkManager.service bluetooth.service
systemctl enable power-profiles-daemon.service 2>/dev/null || true
# Résolution des noms (DNS) : l'installation peut laisser /etc/resolv.conf pointer vers
# systemd-resolved ; on l'active pour que le DNS marche dans tous les cas
systemctl enable systemd-resolved.service

# Bluetooth : pas d'« A2DP duplex », qui rend certaines enceintes muettes
install -Dm644 "$PINKSHEEP_DIR/systeme/wireplumber/51-pinksheep-bluetooth.conf" \
    /etc/wireplumber/wireplumber.conf.d/51-pinksheep-bluetooth.conf

# Pare-feu : tout ce qui sort est permis, rien n'entre sans y être invité
if command -v ufw >/dev/null; then
    sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf
    systemctl enable ufw.service
fi

# Boutique d'applis (Discover) : le catalogue Flathub
if command -v flatpak >/dev/null; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || \
        alerte "Flathub n'a pas pu être ajouté (sans internet ?) : pinksheep-maj le refera."
fi

# ────────────────────────────────────────────────────────────────
etape "Écran de chargement au démarrage"
# Avant le menu GRUB et l'image de démarrage, reconstruits juste après
/usr/local/bin/pinksheep-chargement --sans-regenerer \
    || alerte "écran de chargement non activé (messages du système gardés)"

# ────────────────────────────────────────────────────────────────
etape "Menu de démarrage (dual boot Windows)"
if [[ -f /etc/default/grub ]]; then
    pac -S os-prober ntfs-3g || alerte "os-prober non installé"
    sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    grep -q '^GRUB_DISABLE_OS_PROBER=' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
    sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="PinkSheep"/' /etc/default/grub
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
    # Thème PinkSheep (pour revenir au menu texte : sudo pinksheep-grub --texte)
    if [[ ! -f /etc/pinksheep/grub-texte ]]; then
        /usr/local/bin/pinksheep-grub --theme --sans-mkconfig || alerte "thème GRUB non appliqué (menu texte gardé)"
    fi
    grub-mkconfig -o /boot/grub/grub.cfg || alerte "grub-mkconfig a échoué"
    info "GRUB configuré (Windows apparaîtra dans le menu s'il est détecté)"
elif compgen -G "/boot/loader/entries/*.conf" >/dev/null; then
    sed -i 's/^title\s\+Arch Linux/title   PinkSheep/' /boot/loader/entries/*.conf
    info "systemd-boot : entrées renommées en PinkSheep"
else
    info "Aucun GRUB ni systemd-boot reconnu, rien à faire."
fi

# ────────────────────────────────────────────────────────────────
if [[ "${PINKSHEEP_STYLE:-pinksheep}" == "hyprlust" ]]; then
    etape "Style Hyprlust"
    while IFS=: read -r nom _ uid _ _ home _; do
        (( uid >= 1000 && uid < 60000 )) || continue
        [[ -d "$home" ]] || continue
        runuser -u "$nom" -- env HOME="$home" pinksheep-hyprlust --auto \
            || alerte "$nom : style Hyprlust non appliqué (relance plus tard : pinksheep-hyprlust)"
    done < /etc/passwd
fi

# ────────────────────────────────────────────────────────────────
etape "Reconstruction de l'image de démarrage"
mkinitcpio -P || alerte "mkinitcpio a signalé une erreur (souvent sans gravité, voir le journal)"

printf '%s\n' "$(date +%F)" > /etc/pinksheep/version-installee
# Adresse du dépôt pour « pinksheep-maj » (mises à jour de PinkSheep)
[[ -f "$PINKSHEEP_DIR/depot.conf" && ! -f /etc/pinksheep/depot ]] && cp "$PINKSHEEP_DIR/depot.conf" /etc/pinksheep/depot
[[ -f "$PINKSHEEP_DIR/VERSION" ]] && cp "$PINKSHEEP_DIR/VERSION" /etc/pinksheep/version

printf '\n%sPinkSheep est installé !%s\n' "$ROSE" "$RAZ"
printf '   Redémarre, connecte-toi, puis appuie sur SUPER + H pour voir les raccourcis.\n'
printf '   Journal : %s\n\n' "$LOG"
