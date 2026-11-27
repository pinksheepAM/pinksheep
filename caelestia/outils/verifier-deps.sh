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
sudo pacman -Sy >/dev/null

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
    elif pacman -Si "$dep" >/dev/null 2>&1; then origine="officiel ($(pacman -Si "$dep" | awk -F': ' '/^Repository/ {print $2}'))"
    else origine="MANQUANT"; manquants=$((manquants + 1)); fi
    printf '%-34s %s\n' "$dep" "$origine"
done

echo
for nom in "${!NOS_PAQUETS[@]}"; do
    if pacman -Si "$nom" >/dev/null 2>&1; then
        echo "[!] $nom existe maintenant en officiel : supprimer paquets/${NOS_PAQUETS[$nom]} et tester le lot."
    fi
done
((manquants)) && echo "[X] $manquants dépendance(s) introuvable(s) : recopier leur recette AUR dans paquets/."
((manquants == 0)) && echo "[ok] Toutes les dépendances ont une origine connue."
