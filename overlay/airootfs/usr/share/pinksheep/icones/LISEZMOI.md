# Icônes PinkSheep — proposition (rien n'est activé)

Planche : `python3 outils/planche.py <dossier>` → `planche.png` (fond sombre) et `planche-clair.png`.

Trois directions, mêmes 8 icônes (dossier, maison, Images, Musique, Téléchargements, Documents,
Paramètres, Mises à jour), couleurs prises du fond d'écran par matugen :

- **A · Bonbon** : formes pleines et douces, dossiers en deux tons, symbole foncé ; le mouton sur les applis PinkSheep.
- **B · Trait doux** : contours arrondis de 3 px, presque transparents ; le mouton est la seule forme pleine.
- **C · Galet** : carré très arrondi en dégradé, symbole blanc, petit mouton en filigrane dans le coin.

Mécanique prévue : `index.theme` (hérite de Papirus-Dark pour toutes les icônes pas encore dessinées)
+ `matugen-icones.toml` (copie recolorée dans `~/.local/share/icons/PinkSheep/` à chaque changement de fond).
Une fois la direction choisie : dessiner les suivantes par ordre de visibilité (applis du lanceur, barre, Dolphin).
