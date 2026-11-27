# Nouveautés de PinkSheep

## PinkSheep 1.1.4 (27/11/2026)

- Barre des tâches dans la barre du haut : une icône par fenêtre ouverte. Clic sur l'appli active : elle se réduit ; clic sur une autre : elle s'affiche ; clic du milieu : elle se ferme.
- Réduire une fenêtre : SUPER + R (elle reste dans la barre des tâches, un clic la fait revenir).
- Boutons réduire / agrandir / fermer sur les fenêtres, aux couleurs de ton fond : à installer une fois avec pinksheep-boutons (quelques minutes). Double-clic sur la barre de titre : agrandir.

## PinkSheep 1.1.3 (27/11/2026)

- Écran de chargement : après le menu, un écran PinkSheep (mouton, titre rose, points animés) remplace les messages du système jusqu'à l'écran de connexion. Échap montre les messages ; pour les retrouver à chaque démarrage : sudo pinksheep-chargement --off.
- Le menu ne laisse plus passer les lignes « Chargement de Linux… ».

## PinkSheep 1.1.2 (27/11/2026)

- Démarrage : les messages « Chargement de Linux… » s'affichent dans une carte arrondie aux couleurs du thème, sous le mouton, au lieu d'un grand rectangle noir.

## PinkSheep 1.1.1 (27/11/2026)

- Menu de démarrage (GRUB) aux couleurs de PinkSheep : fond, mouton, menu arrondi, compte à rebours. Pour revenir au menu texte : sudo pinksheep-grub --texte (et sudo pinksheep-grub pour le remettre).
- Discover : correction du démarrage hors de Plasma (paquet qqc2-desktop-style).

## PinkSheep 1.1 « Solide » (27/11/2026)

- Mises à jour : une icône 󰚰 apparaît dans la barre quand il y a des mises à jour (système, applis, PinkSheep), en rouge si l'une corrige une faille connue. Un clic met tout à jour.
- Boutique d'applis : Discover est installé (lanceur : « Discover »), pour les applis Flatpak de Flathub. Il gère volontairement les Flatpak seulement : les paquets Arch restent mis à jour par maj, plus fiable.
- pinksheep-maj vérifie internet avant de télécharger et répare tout seul le DNS en panne.
- Bluetooth : les enceintes qui restaient muettes (Sony SRS-XB100…) marchent. Redémarre le PC une fois pour l'activer.
- Pare-feu activé : rien n'entre dans le PC sans y être invité.
- Installation : assistant Wi-Fi simple (choisir son réseau dans une liste), proposé tout seul avant l'installeur. Mot de passe administrateur séparé et 8 caractères minimum.
- Ménage : Zathura et Newsboat retirés (Okular reste le lecteur PDF).

## PinkSheep 1.0 (15/11/2026)

- Première version : Hyprland, couleurs automatiques depuis le fond d'écran, installeur graphique, écran de connexion PinkSheep, prise en charge NVIDIA.
