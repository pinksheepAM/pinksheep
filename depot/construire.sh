#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  PinkSheep — construit, signe (et publie) le dépôt pacman     │
# │                                                              │
# │  depot/construire.sh                  construit + signe       │
# │  depot/construire.sh --publier        … et met en ligne       │
# │  depot/construire.sh --sans-signature (essais locaux)         │
# │                                                              │
# │  Sur le PC d'Irfane (Arch/PinkSheep), en utilisateur normal,  │
# │  avec la clé créée par depot/creer-cle.sh. Chaque paquet est  │
# │  compilé dans un chroot Arch PROPRE et à jour (devtools).     │
# │  Paquets : depot/paquets/* (paru…), puis caelestia/paquets/*  │
# │  si la branche caelestia est fusionnée (ordre fixé ici).      │
# ╰──────────────────────────────────────────────────────────────╯
set -euo pipefail
ICI="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../overlay/airootfs/usr/share/pinksheep/depot/depot.conf
source "$ICI/overlay/airootfs/usr/share/pinksheep/depot/depot.conf"
CHROOT="${PINKSHEEP_CHROOT:-$HOME/.cache/pinksheep/chroot}"
SORTIE="$ICI/_depot"

PUBLIER=0; SIGNER=1
for a in "$@"; do
    case "$a" in
        --publier) PUBLIER=1 ;;
        --sans-signature) SIGNER=0 ;;
        *) echo "Option inconnue : $a"; exit 1 ;;
    esac
done
((PUBLIER && !SIGNER)) && { echo "On ne publie jamais un dépôt non signé."; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Lance ce script sans sudo (il le demandera)."; exit 1; }
for c in mkarchroot makechrootpkg arch-nspawn repo-add makepkg; do
    command -v "$c" >/dev/null || { echo "Il manque $c : sudo pacman -S --needed devtools base-devel"; exit 1; }
done
if ((SIGNER)); then
    [[ ${#CLE_EMPREINTE} -eq 40 ]] || { echo "Pas de clé déclarée : lance d'abord depot/creer-cle.sh"; exit 1; }
    gpg --list-secret-keys "$CLE_EMPREINTE" >/dev/null 2>&1 \
        || { echo "La clé privée $CLE_EMPREINTE n'est pas sur ce PC (restaure ta sauvegarde)."; exit 1; }
fi

# Liste des paquets, dans l'ordre (chacun peut dépendre des précédents)
paquets=()
for d in "$ICI"/depot/paquets/*/; do paquets+=("${d%/}"); done
# Caelestia (branche caelestia) : même dépôt, même clé, un seul index (sinon les deux
# index s'écraseraient dans la release). pinksheep-instantanes n'y est plus : c'est
# maintenant pinksheep-instantane, livré par pinksheep-maj depuis la 1.1.5.
if [[ -d "$ICI/caelestia/paquets" ]]; then
    CAELESTIA_ORDRE=(python-materialyoucolor libcava ttf-rubik-vf qt6-m3shapes-pinksheep
                     caelestia-cli-pinksheep caelestia-shell-pinksheep pinksheep-caelestia)
    cp "$ICI/caelestia/versions.conf" "$ICI/caelestia/paquets/pinksheep-caelestia/versions.conf"
    for p in "${CAELESTIA_ORDRE[@]}"; do
        [[ -d "$ICI/caelestia/paquets/$p" ]] && paquets+=("$ICI/caelestia/paquets/$p")
    done
fi

echo ":: Chroot de construction ($CHROOT)"
if [[ ! -d "$CHROOT/root" ]]; then
    mkdir -p "$CHROOT"
    mkarchroot "$CHROOT/root" base-devel
else
    arch-nspawn "$CHROOT/root" pacman -Syu --noconfirm
fi

rm -rf "$SORTIE"; mkdir -p "$SORTIE"
locaux=()
for dossier in "${paquets[@]}"; do
    echo ":: Construction de $(basename "$dossier")"
    cd "$dossier"
    rm -f ./*.pkg.tar.zst
    args=()
    for f in "${locaux[@]}"; do args+=(-I "$f"); done
    makechrootpkg -c -r "$CHROOT" "${args[@]}"
    for f in ./*.pkg.tar.zst; do
        [[ "$f" == *-debug-* ]] && continue
        cp "$f" "$SORTIE/"
        locaux+=("$SORTIE/$(basename "$f")")
    done
done

echo ":: Index du dépôt"
cd "$SORTIE"
if ((SIGNER)); then
    for f in ./*.pkg.tar.zst; do gpg --batch --yes -u "$CLE_EMPREINTE" --detach-sign --no-armor "$f"; done
    repo-add --sign --key "$CLE_EMPREINTE" --verify "$DEPOT_NOM.db.tar.zst" ./*.pkg.tar.zst
else
    repo-add "$DEPOT_NOM.db.tar.zst" ./*.pkg.tar.zst
fi

if ((PUBLIER)); then
    command -v gh >/dev/null || { echo "Il manque gh : sudo pacman -S github-cli, puis gh auth login"; exit 1; }
    echo ":: Publication (release GitHub « $DEPOT_RELEASE »)"
    envoi="$(mktemp -d)"
    cp -L ./*.pkg.tar.zst ./*.pkg.tar.zst.sig "$envoi/"
    for ext in db db.sig files files.sig; do cp -L "$DEPOT_NOM.$ext" "$envoi/$DEPOT_NOM.$ext"; done
    gh release view "$DEPOT_RELEASE" >/dev/null 2>&1 || \
        gh release create "$DEPOT_RELEASE" --title "Dépôt pacman PinkSheep" \
            --notes "Paquets PinkSheep signés. Ne pas supprimer : pacman télécharge ici."
    # --clobber remplace l'index ; les anciens paquets restent en ligne (retour arrière possible)
    gh release upload "$DEPOT_RELEASE" "$envoi"/* --clobber
    rm -rf "$envoi"
fi
echo ":: Terminé. Dépôt local : $SORTIE"
