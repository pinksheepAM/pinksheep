# Dépôt pacman PinkSheep (paquets signés)

Les paquets que PinkSheep construit lui-même (paru, puis Caelestia) sont rangés dans
un dépôt pacman **signé avec ta clé**. Sur chaque PC, pacman refuse tout paquet qui
n'est pas signé par cette clé (`SigLevel = Required`), et le dépôt est placé après
ceux d'Arch : il ne peut pas remplacer un paquet officiel.

Hébergement : la « release » GitHub `depot` du dépôt PinkSheep (gratuit, ne gonfle
pas l'historique git, les anciens paquets restent téléchargeables pour revenir en
arrière). Adresse : `https://github.com/pinksheepAM/pinksheep/releases/download/depot`.

Tant que la clé n'existe pas, **rien ne change** sur les PC (`pinksheep-depot --etat`).

## Ouvrir le dépôt (une fois, sur ton PC)

1. `sudo pacman -S --needed devtools base-devel github-cli gnupg` puis `gh auth login`
2. Dans ton clone du dépôt PinkSheep : `depot/creer-cle.sh`
   (phrase secrète longue, puis suis les 4 étapes affichées : sauvegarde de la clé
   privée et du certificat de révocation sur une clé USB, commit de la clé PUBLIQUE).
3. `depot/construire.sh --publier` (compile paru dans un chroot propre, signe, publie).
4. Sur chaque PC : `pinksheep-maj` active le dépôt et installe paru
   (ou tout de suite : `sudo pinksheep-depot`).

## Ensuite

- Nouvelle version d'un paquet : modifier sa recette (`depot/paquets/<nom>/PKGBUILD`,
  version figée + somme sha256), puis `depot/construire.sh --publier`.
- Caelestia (branche `caelestia`) : ses paquets sont ajoutés automatiquement à la
  construction quand `caelestia/paquets/` existe (même dépôt, même clé, un seul index).
  À la fusion, aligner `caelestia/versions.conf` sur `depot.conf` (release `depot`,
  pas `depot-x86_64`) et retirer `caelestia/outils/construire-depot.sh` et
  `pinksheep-instantanes` (remplacé par pinksheep-instantane en 1.1.5).
- La clé n'est jamais dans git : seule `pinksheep.asc` (publique) et son empreinte
  (`depot.conf`) le sont. Clé perdue = restaurer la sauvegarde USB.
