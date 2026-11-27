#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  PinkSheep — construit le dépôt pacman de Caelestia           │
# │                                                              │
# │  outils/construire-depot.sh             construit + signe     │
# │  outils/construire-depot.sh --publier   … et met en ligne     │
# │  outils/construire-depot.sh --sans-signature  (tests locaux)  │
# │                                                              │
# │  Chaque paquet est compilé dans un chroot Arch PROPRE et à    │
# │  jour (devtools) : le résultat ne dépend pas de ce qui est    │
# │  installé sur la machine qui construit.                       │
# │  À lancer en utilisateur normal (pas avec sudo), sur Arch.    │
# ╰──────────────────────────────────────────────────────────────╯
set -euo pipefail
ICI="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../versions.conf
source "$ICI/versions.conf"

PUBLIER=0; SIGNER=1
for a in "$@"; do
    case "$a" in
        --publier) PUBLIER=1 ;;
        --sans-signature) SIGNER=0 ;;
        *) echo "Option inconnue : $a"; exit 1 ;;
    esac
done
((PUBLIER && !SIGNER)) && { echo "On ne publie jamais un dépôt non signé."; exit 1; }

# Ordre de construction : chaque paquet peut dépendre des précédents
ORDRE=(python-materialyoucolor libcava ttf-rubik-vf qt6-m3shapes-pinksheep
       caelestia-cli-pinksheep caelestia-shell-pinksheep pinksheep-caelestia pinksheep-instantanes)
CHROOT="${PINKSHEEP_CHROOT:-$HOME/.cache/pinksheep/chroot}"
SORTIE="$ICI/_depot"

[[ $EUID -ne 0 ]] || { echo "Lance ce script sans sudo (il le demandera)."; exit 1; }
for c in mkarchroot makechrootpkg arch-nspawn repo-add; do
    command -v "$c" >/dev/null || { echo "Il manque $c : sudo pacman -S --needed devtools"; exit 1; }
done
if ((SIGNER)); then
    [[ "$CLE_EMPREINTE" != A_REMPLIR ]] || { echo "Renseigne CLE_EMPREINTE dans versions.conf (gpg --list-secret-keys)."; exit 1; }
    gpg --list-secret-keys "$CLE_EMPREINTE" >/dev/null || { echo "Clé GPG $CLE_EMPREINTE introuvable."; exit 1; }
fi

echo ":: Chroot de construction ($CHROOT)"
if [[ ! -d "$CHROOT/root" ]]; then
    mkdir -p "$CHROOT"
    mkarchroot "$CHROOT/root" base-devel
else
    arch-nspawn "$CHROOT/root" pacman -Syu --noconfirm
fi

cp "$ICI/versions.conf" "$ICI/paquets/pinksheep-caelestia/versions.conf"
rm -rf "$SORTIE"; mkdir -p "$SORTIE"
locaux=()
for p in "${ORDRE[@]}"; do
    echo ":: Construction de $p"
    cd "$ICI/paquets/$p"
    rm -f ./*.pkg.tar.zst
    if [[ "$p" == pinksheep-caelestia || "$p" == pinksheep-instantanes ]]; then
        # Paquets sans compilation (fichiers et scripts) : pas besoin du chroot
        makepkg --nodeps --clean --force
    else
        args=()
        for f in "${locaux[@]}"; do args+=(-I "$f"); done
        makechrootpkg -c -r "$CHROOT" "${args[@]}"
    fi
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
    gpg --armor --export "$CLE_EMPREINTE" > "$SORTIE/cle-publique.asc"
else
    repo-add "$DEPOT_NOM.db.tar.zst" ./*.pkg.tar.zst
fi

# Ce qui a servi à construire ce lot (pour savoir quand reconstruire)
{
    echo "Lot $LOT construit le $(date '+%d/%m/%Y %H:%M')"
    arch-nspawn "$CHROOT/root" pacman -Q qt6-base qt6-declarative python quickshell hyprland 2>/dev/null || true
} > "$SORTIE/etat-du-lot.txt"
cat "$SORTIE/etat-du-lot.txt"

if ((PUBLIER)); then
    command -v gh >/dev/null || { echo "Il manque gh : sudo pacman -S github-cli"; exit 1; }
    echo ":: Publication ($DEPOT_RELEASE)"
    envoi="$(mktemp -d)"
    cp -L ./*.pkg.tar.zst ./*.pkg.tar.zst.sig cle-publique.asc etat-du-lot.txt "$envoi/"
    for ext in db db.sig files files.sig; do cp -L "$DEPOT_NOM.$ext" "$envoi/$DEPOT_NOM.$ext"; done
    gh release view "$DEPOT_RELEASE" >/dev/null 2>&1 || \
        gh release create "$DEPOT_RELEASE" --title "Dépôt pacman PinkSheep" \
            --notes "Paquets PinkSheep (Caelestia et outils). Ne pas supprimer : pacman télécharge ici."
    # --clobber remplace l'index ; les anciens paquets restent en ligne (retour arrière possible)
    gh release upload "$DEPOT_RELEASE" "$envoi"/* --clobber
    rm -rf "$envoi"
fi
echo ":: Terminé. Dépôt local : $SORTIE"
