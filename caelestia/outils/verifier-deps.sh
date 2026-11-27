#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  PinkSheep — d'où vient chaque dépendance ?                   │
# │  À lancer sur une Arch à jour (la VM atelier).                │
# │    officiel   : dans les dépôts Arch, rien à faire            │
# │    PinkSheep  : construit par nous (dossier paquets/)         │
# │    MANQUANT   : ni l'un ni l'autre → recopier sa recette AUR  │
# │  Signale aussi une copie PinkSheep d'un paquet devenu         │
# │  officiel (à supprimer : on ne masque jamais l'officiel).     │
# ╰──────────────────────────────────────────────────────────────╯
set -uo pipefail
ICI="$(cd "$(dirname "$0")/.." && pwd)"
command -v pacman >/dev/null || { echo "À lancer sur Arch Linux."; exit 1; }
command -v fakeroot >/dev/null || { echo "Il manque fakeroot : sudo pacman -S --needed base-devel"; exit 1; }

# Base des dépôts PRIVÉE et à jour (comme checkupdates) : pas de sudo, et pas de
# « pacman -Sy » sur le système, qui laisserait une mise à jour partielle.
BASE="$(mktemp -d)"; trap 'rm -rf "$BASE"' EXIT
ln -s /var/lib/pacman/local "$BASE/local"
synchro() { fakeroot -- pacman -Sy --dbpath "$BASE" --logfile /dev/null "$@" >/dev/null 2>&1; }
synchro --disable-sandbox || synchro || { echo "Synchronisation des dépôts impossible (internet ?)."; exit 1; }
pac() { LC_ALL=C pacman --dbpath "$BASE" "$@"; }

declare -A NOS_PAQUETS=()
for d in "$ICI"/paquets/*/; do
    nom="$(cd "$d" && bash -c 'source ./PKGBUILD >/dev/null 2>&1; echo "$pkgname"')"
    NOS_PAQUETS[$nom]="$(basename "$d")"
done

mapfile -t DEPS < <(for d in "$ICI"/paquets/*/; do
    (cd "$d" && bash -c 'source ./PKGBUILD >/dev/null 2>&1; printf "%s\n" "${depends[@]}" "${makedepends[@]}"')
done | sed -E 's/[<>=].*//' | sort -u)

manquants=0
printf '%-34s %s\n' "DÉPENDANCE" "ORIGINE"
for dep in "${DEPS[@]}"; do
    [[ -z "$dep" ]] && continue
    if [[ -n "${NOS_PAQUETS[$dep]:-}" ]]; then origine="PinkSheep"
    # -Sp résout aussi les noms virtuels (ex. sdl2 fourni par sdl2-compat)
    elif fourni="$(pac -Sp --print-format '%r/%n' "$dep" 2>/dev/null | tail -n1)" && [[ -n "$fourni" ]]; then
        origine="officiel ($fourni)"
    else origine="MANQUANT"; manquants=$((manquants + 1)); fi
    printf '%-34s %s\n' "$dep" "$origine"
done

echo
for nom in "${!NOS_PAQUETS[@]}"; do
    if pac -Si "$nom" >/dev/null 2>&1; then
        echo "[!] $nom existe maintenant en officiel : supprimer paquets/${NOS_PAQUETS[$nom]} et tester le lot."
    fi
done
((manquants)) && echo "[X] $manquants dépendance(s) introuvable(s) : recopier leur recette AUR dans paquets/."
((manquants == 0)) && echo "[ok] Toutes les dépendances ont une origine connue."
