#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  PinkSheep — fabrique l'ISO                                    │
# │                                                              │
# │  À lancer sur une Arch Linux (PC, VM ou WSL) :                │
# │      sudo ./build.sh                                         │
# │                                                              │
# │  Principe : on part du profil officiel de l'ISO Arch          │
# │  (« releng », fourni par le paquet archiso), on y ajoute      │
# │  les fichiers de overlay/, puis mkarchiso fabrique l'ISO.     │
# │                                                              │
# │  L'installeur graphique (Calamares) n'est pas dans les dépôts │
# │  officiels : il est compilé depuis l'AUR la première fois     │
# │  (~10-20 min), puis réutilisé aux constructions suivantes.    │
# │  Options :                                                   │
# │      --sans-graphique        ISO avec l'installeur texte seul │
# │      --recompiler-calamares  force une nouvelle compilation   │
# │  Résultat : iso/pinksheep-AAAA.MM.JJ-x86_64.iso                │
# │                                                              │
# │  ⚠ Il modifie la machine qui construit : mise à jour complète │
# │  du système (pacman -Syu) + archiso, dépendances de Calamares │
# │  installées, dossier /var/tmp/pinksheep-aur, éventuellement   │
# │  un compte « pinksheep-build ». Fait pour la VM atelier.      │
# │  Sur un PC de tous les jours : compiler Calamares à part dans │
# │  un chroot propre (makechrootpkg), le déposer dans            │
# │  _construction/depot/ ; build.sh le réutilise sans rien       │
# │  installer d'autre que archiso.                               │
# ╰──────────────────────────────────────────────────────────────╯
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONSTRUCTION="$ICI/_construction"     # fichiers temporaires (plusieurs Go)
PROFIL="$CONSTRUCTION/profil"
DEPOT="$CONSTRUCTION/depot"           # dépôt local avec Calamares compilé
SORTIE="$ICI/iso"
AUR_TRAVAIL=/var/tmp/pinksheep-aur

GRAPHIQUE=1
RECOMPILER=0
for arg in "$@"; do
    case "$arg" in
        --sans-graphique)       GRAPHIQUE=0 ;;
        --recompiler-calamares) RECOMPILER=1 ;;
    esac
done

ROSE=$'\e[38;2;255;126;182m'; ROUGE=$'\e[1;31m'; JAUNE=$'\e[33m'; RAZ=$'\e[0m'
etape()  { printf '\n%s:: %s%s\n' "$ROSE" "$*" "$RAZ"; }
alerte() { printf '%s[!] %s%s\n' "$JAUNE" "$*" "$RAZ"; }
erreur() { printf '\n%s[X] %s%s\n' "$ROUGE" "$*" "$RAZ"; exit 1; }

[[ -f /etc/arch-release ]] || erreur "Il faut lancer ce script sur une Arch Linux (VM, PC ou WSL)."
if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

etape "Installation des outils (archiso)"
# Jamais « -Sy » seul : ça laisserait le système à moitié mis à jour
pacman -Syu --needed --noconfirm archiso

# ────────────────────────────────────────────────────────────────
# Calamares (installeur graphique) depuis l'AUR
# ────────────────────────────────────────────────────────────────
# makepkg refuse de tourner en root : on compile avec ton compte
# (celui qui a lancé sudo) ou, à défaut, un compte temporaire.
utilisateur_compilation() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != root ]]; then
        printf '%s' "$SUDO_USER"
    else
        id pinksheep-build >/dev/null 2>&1 || useradd -m -r pinksheep-build
        printf 'pinksheep-build'
    fi
}

# Installe les dépendances listées dans un PKGBUILD (depends + makedepends)
installer_dependances() {
    local deps
    deps="$(bash -c 'source "$1" >/dev/null 2>&1; printf "%s\n" "${depends[@]}" "${makedepends[@]}"' _ "$1" \
            | sed 's/[<>=].*//' | grep -v '^$' | sort -u)"
    # shellcheck disable=SC2086
    pacman -S --needed --noconfirm $deps
}

# Recettes AUR figées : on compile toujours CETTE version, relue, jamais « la dernière ».
# Format : paquet → « commit de la recette AUR | sha256 du PKGBUILD à ce commit ».
# Pour passer à une nouvelle version : relire le PKGBUILD, puis mettre à jour les deux valeurs.
declare -A AUR_FIGE=(
    [calamares]="167151beb537c06cb75c8dbfd409799ba308bb66|8ea0869d8f366ef043693815000aabf7caefedb52cf53a9150f46194cb2bd9c2"  # 3.4.2-2
)

# Compile un paquet AUR et le copie dans le dépôt local
compiler_aur() {
    local paquet="$1" patch="${2:-}" qui fige commit somme
    qui="$(utilisateur_compilation)"
    rm -rf "${AUR_TRAVAIL:?}/$paquet"
    mkdir -p "$AUR_TRAVAIL"
    chown "$qui" "$AUR_TRAVAIL"
    fige="${AUR_FIGE[$paquet]:-}"
    # Version figée : prise sur le miroir officiel de l'AUR chez GitHub (où son commit a été vérifié)
    if [[ -z "$fige" ]]; then
        runuser -u "$qui" -- git clone -q "https://aur.archlinux.org/$paquet.git" "$AUR_TRAVAIL/$paquet"
    fi
    if [[ ! -d "$AUR_TRAVAIL/$paquet/.git" ]]; then
        runuser -u "$qui" -- git clone -q --branch "$paquet" --single-branch \
            https://github.com/archlinux/aur.git "$AUR_TRAVAIL/$paquet" || return 1
    fi
    if [[ -n "$fige" ]]; then
        commit="${fige%%|*}"; somme="${fige##*|}"
        runuser -u "$qui" -- git -C "$AUR_TRAVAIL/$paquet" checkout -q "$commit" 2>/dev/null \
            || { alerte "$paquet : version figée $commit introuvable"; return 1; }
        if ! echo "$somme  $AUR_TRAVAIL/$paquet/PKGBUILD" | sha256sum -c --quiet - 2>/dev/null; then
            alerte "$paquet : le PKGBUILD ne correspond pas à la version vérifiée, compilation refusée"
            return 1
        fi
        printf "   %s : recette AUR figée %s, vérifiée\n" "$paquet" "${commit:0:7}"
    fi
    if [[ -n "$patch" ]]; then
        sed -i "$patch" "$AUR_TRAVAIL/$paquet/PKGBUILD"
    fi
    installer_dependances "$AUR_TRAVAIL/$paquet/PKGBUILD" || return 1
    runuser -u "$qui" -- bash -c "cd '$AUR_TRAVAIL/$paquet' && makepkg --noconfirm --cleanbuild --force" || return 1
    cp "$AUR_TRAVAIL/$paquet"/*.pkg.tar.zst "$DEPOT/"
}

CALAMARES=0          # 1 = installeur graphique disponible
CHOIX_STYLE=1        # 1 = page « style » (PinkSheep / Hyprlust) dans l'installeur
if [[ $GRAPHIQUE -eq 1 ]]; then
    mkdir -p "$DEPOT"
    if [[ $RECOMPILER -eq 1 ]]; then rm -f "$DEPOT"/calamares-*.pkg.tar.zst "$DEPOT"/pinksheep-local.*; fi

    if compgen -G "$DEPOT/calamares-*.pkg.tar.zst" >/dev/null; then
        etape "Installeur graphique : Calamares déjà compilé, on le réutilise"
        CALAMARES=1
        [[ -f "$DEPOT/.sans-choix-style" ]] && CHOIX_STYLE=0
    else
        etape "Installeur graphique : compilation de Calamares (une seule fois, 10-20 min)"
        pacman -S --needed --noconfirm base-devel git python
        # Le paquet AUR désactive la page de choix (packagechooser) : on la réactive
        if compiler_aur calamares '/^[[:space:]]*packagechooser$/d'; then
            CALAMARES=1
            rm -f "$DEPOT/.sans-choix-style"
        else
            alerte "Échec avec la page de choix du style, nouvel essai sans elle…"
            if compiler_aur calamares; then
                CALAMARES=1; CHOIX_STYLE=0
                touch "$DEPOT/.sans-choix-style"
            else
                alerte "Calamares n'a pas pu être compilé : l'ISO n'aura que l'installeur texte."
            fi
        fi
    fi
    if [[ $CALAMARES -eq 1 ]]; then
        rm -f "$DEPOT"/pinksheep-local.*
        repo-add -q "$DEPOT/pinksheep-local.db.tar.gz" "$DEPOT"/*.pkg.tar.zst
    fi
fi

# ────────────────────────────────────────────────────────────────
etape "Préparation du profil à partir de l'ISO Arch officielle"
rm -rf "$PROFIL"
mkdir -p "$CONSTRUCTION" "$SORTIE"
cp -r /usr/share/archiso/configs/releng "$PROFIL"

etape "Ajout des fichiers PinkSheep"
cp -rT "$ICI/overlay/airootfs" "$PROFIL/airootfs"
# Version (= dernier commit du dépôt), pour que « pinksheep-maj » sache où en est le système
if git -C "$ICI" rev-parse HEAD >/dev/null 2>&1; then
    git -c safe.directory="$ICI" -C "$ICI" log -1 --format='%h — %s (%cd)' --date=format:'%d/%m/%Y' \
        > "$PROFIL/airootfs/usr/share/pinksheep/VERSION"
fi

# Paquets supplémentaires du système live
grep -Ev '^\s*(#|$)' "$ICI/overlay/packages.extra" >> "$PROFIL/packages.x86_64"

if [[ $CALAMARES -eq 1 ]]; then
    grep -Ev '^\s*(#|$)' "$ICI/overlay/packages.graphique" >> "$PROFIL/packages.x86_64"
    # Dépôt local (uniquement pour fabriquer l'ISO, pas dans le système live)
    cat >> "$PROFIL/pacman.conf" <<EOF

[pinksheep-local]
SigLevel = Optional TrustAll
Server = file://$DEPOT
EOF
    if [[ $CHOIX_STYLE -eq 0 ]]; then
        # Calamares sans page de choix : style PinkSheep par défaut
        sed -i '/packagechooser@style/d; /# DEBUT-STYLE/,/# FIN-STYLE/d' "$PROFIL/airootfs/etc/calamares/settings.conf"
        sed -i 's/\${gs\[packagechooser_style\]}/pinksheep/' \
            "$PROFIL/airootfs/etc/calamares/modules/shellprocess-pinksheep.conf"
    fi
else
    rm -rf "$PROFIL/airootfs/etc/calamares"
fi
sort -u -o "$PROFIL/packages.x86_64" "$PROFIL/packages.x86_64"

# Nom, étiquette et droits des fichiers (profiledef.sh est un script bash :
# les lignes ajoutées à la fin remplacent les valeurs du dessus)
cat >> "$PROFIL/profiledef.sh" <<'EOF'

# ── PinkSheep ──
iso_name="pinksheep"
iso_label="PINKSHEEP_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="PinkSheep"
iso_application="PinkSheep — clé live et installation"
file_permissions+=(
  ["/usr/local/bin/pinksheep-install"]="0:0:755"
  ["/usr/local/bin/pinksheep-demarrage"]="0:0:755"
  ["/usr/local/bin/pinksheep-graphique"]="0:0:755"
  ["/usr/local/bin/pinksheep-wifi"]="0:0:755"
  ["/usr/share/pinksheep/setup.sh"]="0:0:755"
)
EOF

# Menus de démarrage : « Arch Linux install medium » → PinkSheep
find "$PROFIL/grub" "$PROFIL/syslinux" "$PROFIL/efiboot" -type f \( -name '*.cfg' -o -name '*.conf' \) \
    -exec sed -i -e 's/Arch Linux install medium/PinkSheep live/g' \
                 -e 's/MENU TITLE Arch Linux/MENU TITLE PinkSheep/g' {} +

# Image de fond du menu de démarrage (BIOS)
if [[ -f "$PROFIL/syslinux/splash.png" ]]; then
    cp "$ICI/overlay/airootfs/usr/share/pinksheep/branding/splash.png" "$PROFIL/syslinux/splash.png"
fi

# Le menu PinkSheep (installeur graphique / texte) se lance tout seul sur le premier écran
cat >> "$PROFIL/airootfs/root/.zlogin" <<'EOF'

# PinkSheep : menu d'installation automatique sur tty1
if [[ "$(tty)" == /dev/tty1 && -z "${PINKSHEEP_DEJA_LANCE:-}" ]]; then
    export PINKSHEEP_DEJA_LANCE=1
    pinksheep-demarrage
fi
EOF

etape "Fabrication de l'ISO (10 à 30 min, ~2 Go de téléchargement)"
rm -rf "$CONSTRUCTION/travail"
mkarchiso -v -w "$CONSTRUCTION/travail" -o "$SORTIE" "$PROFIL"

ISO="$(ls -t "$SORTIE"/pinksheep-*.iso | head -n1)"
( cd "$SORTIE" && sha256sum "$(basename "$ISO")" > "$(basename "$ISO").sha256" )

etape "Nettoyage"
rm -rf "$CONSTRUCTION/travail"

printf '\n%sISO prête :%s %s (%s)\n' "$ROSE" "$RAZ" "$ISO" "$(du -h "$ISO" | cut -f1)"
if [[ $CALAMARES -eq 1 ]]; then
    printf 'Installeur graphique : inclus%s\n' "$([[ $CHOIX_STYLE -eq 0 ]] && echo ' (sans la page de choix du style)')"
else
    printf 'Installeur graphique : non inclus (installeur texte seulement)\n'
fi
printf 'Copie-la sur une clé USB avec Ventoy, Rufus (mode DD) ou :\n'
printf '    sudo dd if=%s of=/dev/sdX bs=4M status=progress oflag=sync\n\n' "$ISO"
