# Nouveautés de PinkSheep

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
