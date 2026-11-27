#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  PinkSheep — installe la session Caelestia sur un PC          │
# │  déjà sous PinkSheep. Rien n'est retiré : la session          │
# │  « PinkSheep classique » reste disponible.                    │
# │                                                              │
# │  sudo outils/activer-caelestia.sh                (en ligne)   │
# │  sudo outils/activer-caelestia.sh --depot-local DOSSIER       │
# │       (premier test, avec le dépôt construit sur ce PC)       │
# ╰──────────────────────────────────────────────────────────────╯
set -euo pipefail
ICI="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../versions.conf
source "$ICI/versions.conf"
[[ $EUID -eq 0 ]] || exec sudo "$0" "$@"

LOCAL=""
if [[ "${1:-}" == --depot-local ]]; then
    LOCAL="$(realpath "${2:?Indique le dossier du dépôt (_depot)}")"
    [[ -f "$LOCAL/$DEPOT_NOM.db" ]] || { echo "Pas de dépôt dans $LOCAL"; exit 1; }
fi

echo ":: Dépôt PinkSheep dans /etc/pacman.conf"
cp /etc/pacman.conf "/etc/pacman.conf.avant-caelestia"
sed -i "/^\[$DEPOT_NOM\]/,/^$/d" /etc/pacman.conf
# Placé APRÈS les dépôts officiels : un paquet officiel du même nom gagne toujours.
if [[ -n "$LOCAL" ]]; then
    printf '\n[%s]\nSigLevel = Optional TrustAll\nServer = file://%s\n\n' "$DEPOT_NOM" "$LOCAL" >> /etc/pacman.conf
else
    [[ "$CLE_EMPREINTE" != A_REMPLIR ]] || { echo "CLE_EMPREINTE manquante dans versions.conf"; exit 1; }
    curl -fsSL "$DEPOT_URL/cle-publique.asc" -o /tmp/pinksheep-cle.asc
    pacman-key --add /tmp/pinksheep-cle.asc
    pacman-key --lsign-key "$CLE_EMPREINTE"
    printf '\n[%s]\nSigLevel = Required DatabaseRequired\nServer = %s\n\n' "$DEPOT_NOM" "$DEPOT_URL" >> /etc/pacman.conf
fi

echo ":: Installation (avec mise à jour complète du système, comme toujours sur Arch)"
pacman -Syu --needed pinksheep-caelestia

echo ":: Vérification"
pinksheep-caelestia-verifier || true

cat <<'FIN'

C'est installé. Pour essayer :
  1. Déconnecte-toi (SUPER + Échap → Se déconnecter).
  2. En bas de l'écran de connexion, choisis « PinkSheep (Caelestia) ».
  3. Si quelque chose ne va pas, choisis « PinkSheep classique » : rien n'a été modifié.

Un instantané Timeshift est pris avant chaque mise à jour (PinkSheep 1.1.5) :
en cas de souci, sudo timeshift --restore.
FIN
