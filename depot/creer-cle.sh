#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  PinkSheep — créer LA clé de signature du dépôt pacman        │
# │                                                              │
# │  À lancer UNE SEULE FOIS, par Irfane, sur SON PC, dans le     │
# │  dossier du dépôt git PinkSheep :   depot/creer-cle.sh        │
# │                                                              │
# │  - La clé PRIVÉE reste dans ton trousseau GPG (~/.gnupg),     │
# │    protégée par une phrase secrète. Elle ne va JAMAIS dans    │
# │    git, ni dans un message, ni chez Claude.                   │
# │  - Seule la clé PUBLIQUE est copiée dans le dépôt, avec son   │
# │    empreinte : c'est ce que les PC PinkSheep vérifient.       │
# ╰──────────────────────────────────────────────────────────────╯
set -euo pipefail
ICI="$(cd "$(dirname "$0")/.." && pwd)"
CONF="$ICI/overlay/airootfs/usr/share/pinksheep/depot/depot.conf"
# shellcheck source=../overlay/airootfs/usr/share/pinksheep/depot/depot.conf
source "$CONF"
PUBLIQUE="$ICI/overlay/airootfs/usr/share/pinksheep/depot/$DEPOT_NOM.asc"
NOM="Dépôt PinkSheep (signature des paquets)"   # pas d'adresse mail : elle serait publique

[[ $EUID -ne 0 ]] || { echo "Sans sudo : la clé doit être dans TON trousseau."; exit 1; }
command -v gpg >/dev/null || { echo "Il manque gpg : sudo pacman -S gnupg"; exit 1; }
if [[ -n "$CLE_EMPREINTE" ]]; then
    echo "Une clé est déjà déclarée ($CLE_EMPREINTE). On n'en crée pas une deuxième."
    echo "(Changer de clé = tous les PC devront la refaire confiance : à éviter.)"
    exit 1
fi

echo "Création de la clé « $NOM » (ed25519, valable 3 ans)."
echo "GPG va te demander une PHRASE SECRÈTE : longue, notée dans ton gestionnaire de mots de passe."
gpg --quick-generate-key "$NOM" ed25519 sign 3y

empreinte="$(gpg --list-secret-keys --with-colons "$NOM" | awk -F: '/^fpr:/ {print $10; exit}')"
[[ ${#empreinte} -eq 40 ]] || { echo "Empreinte introuvable : arrêt."; exit 1; }

gpg --armor --export "$empreinte" > "$PUBLIQUE"
sed -i "s/^CLE_EMPREINTE=.*/CLE_EMPREINTE=$empreinte/" "$CONF"

cat <<EOF

Clé créée.  Empreinte : $empreinte

À FAIRE MAINTENANT (une fois) :
 1. Sauvegarde la clé PRIVÉE hors du PC (clé USB rangée à part) :
      gpg --armor --export-secret-keys $empreinte > /chemin/usb/pinksheep-cle-privee.asc
    Sans elle, impossible de publier de nouveaux paquets si ce PC meurt.
 2. Certificat de révocation (au cas où la clé serait volée), sur la même clé USB :
      gpg --output /chemin/usb/pinksheep-revocation.asc --gen-revoke $empreinte
 3. Vérifie puis envoie seulement la partie PUBLIQUE dans git :
      git diff --stat     (doivent changer : depot.conf et $DEPOT_NOM.asc, rien d'autre)
      git add overlay/airootfs/usr/share/pinksheep/depot && git commit -m "Dépôt : clé publique" && git push
 4. Construis et publie le dépôt : depot/construire.sh --publier
EOF
