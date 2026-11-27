# 🐑 PinkSheep

Ta distribution Linux perso : base **Arch Linux**, bureau **Hyprland** (config Lua, version 0.57+), **couleurs générées automatiquement à partir du fond d'écran**, outils de terminal stylés, et pilotes graphiques détectés automatiquement (dont ta **GTX 1660 Super**).

---

## Ce qu'il y a dedans

| | |
|---|---|
| **Bureau** | Hyprland + barre Waybar + lanceur Rofi + notifications SwayNC + verrouillage hyprlock + veille hypridle |
| **Thème automatique** | `SUPER+W` : tu choisis un fond d'écran (miniatures + transition animée) et **tout le bureau se recolore** avec ses couleurs : bordures, barre, lanceur, notifications, terminal, Neovim, btop, Yazi, cava, écran de verrouillage, menu d'extinction, applis GTK et Qt. Par défaut : rose. |
| **Fonds fournis** | 5 paysages PinkSheep (rose, forêt, océan de nuit, coucher de soleil, aurore). Ajoute les tiens dans `Images/FondsEcran`. |
| **Terminal stylé** | Zsh + Starship + suggestions automatiques + coloration, Yazi (fichiers avec aperçu des images), Neovim, fzf, zoxide, eza, bat |
| **Style Hyprlust (au choix)** | À l'installation (ou plus tard avec `pinksheep-hyprlust`) : les configs du dépôt [Hyprlust](https://github.com/NischalDawadi/Hyprlust) (barre, lanceur, notifications, terminal, fastfetch, rmpc, Yazi, btop, Neovim, mpv…) adaptées à PinkSheep. Leurs couleurs suivent aussi le fond d'écran. Réversible. |
| **Musique & vidéo dans le terminal** | rmpc + mpd pour ta musique, `pinksheep-yt` pour chercher et regarder YouTube sans navigateur, cava (visualiseur audio) |
| **Écran de connexion** | Thème PinkSheep : horloge, carte de connexion rose, choix de session, clavier AZERTY, boutons Éteindre / Redémarrer / Veille |
| **Repères Windows** | `SUPER+E` fichiers, `SUPER+L` verrouiller, `ALT+F4` fermer, `ALT+Tab`, `SUPER+SHIFT+S` capture, `CTRL+SHIFT+Échap` gestionnaire des tâches |
| **Aide intégrée** | `SUPER+H` affiche tous les raccourcis (s'ouvre tout seul au premier lancement) |
| **Applis** | Firefox, Dolphin, Kate, Okular, Gwenview, mpv, LibreOffice, Steam, Discord, OBS, btop… |
| **Pilotes** | NVIDIA (modules open, Turing et plus récentes), AMD, Intel : choisis automatiquement |
| **Dual boot** | GRUB + os-prober pour garder Windows dans le menu de démarrage |
| **Démarrage** | Menu GRUB et écran de chargement (Plymouth) aux couleurs de PinkSheep |
| **Clavier** | AZERTY détecté ; raccourcis des bureaux 1-10 qui marchent en AZERTY comme en QWERTY |

---

## Organisation du projet

```
pinksheep/
├── build.sh                    ← fabrique l'ISO (à lancer sur Arch)
├── LISEZMOI.md
└── overlay/
    ├── packages.extra          ← paquets en plus sur la clé live
    ├── packages.graphique      ← paquets de l'installeur graphique
    └── airootfs/               ← fichiers copiés dans le système live
        ├── etc/                    motd, clavier fr, nom de machine
        │   └── calamares/          ← installeur graphique (pages, modules, apparence)
        ├── usr/local/bin/
        │   ├── pinksheep-demarrage  ← menu de la clé live
        │   ├── pinksheep-graphique  ← lance l'installeur graphique
        │   └── pinksheep-install    ← l'installeur texte
        └── usr/share/pinksheep/
            ├── setup.sh            ← transforme Arch en PinkSheep
            ├── paquets.txt         ← LA liste des applis (modifiable)
            ├── bin/                ← petits outils (aide, captures, menu power…)
            ├── skel/.config/       ← toutes les configs (hypr, waybar, rofi, kitty…)
            │   └── matugen/        ← les modèles de couleurs (1 par appli)
            ├── wallpapers/
            └── branding/           ← logo, image de démarrage
```

L'ISO est construite à partir du profil officiel de l'ISO Arch (`releng`) : PinkSheep ne fait qu'ajouter ses fichiers par-dessus. Donc à chaque nouvelle version d'archiso, ta distro suit automatiquement.

---

## 1. Fabriquer l'ISO

Il faut une Arch Linux pour construire l'ISO. Ta VM Omarchy fait l'affaire (Omarchy est basé sur Arch).

1. Dans VirtualBox, donne à la VM **au moins 4 Go de RAM et 15 Go d'espace libre**.
2. Récupère le projet depuis ton dépôt GitHub (privé) :
   ```bash
   sudo pacman -S --needed git github-cli
   gh auth login          # GitHub.com → HTTPS → connexion par navigateur
   gh auth setup-git
   git clone https://github.com/pinksheepAM/pinksheep.git
   ```
   Les fois suivantes, il suffit de `cd pinksheep && git pull`.
   *(Sans GitHub : dézippe `pinksheep.zip` à la place.)*
3. Dans un terminal de la VM :
   ```bash
   cd pinksheep
   sudo ./build.sh
   ```
4. Compte 10 à 30 minutes. L'ISO arrive dans `pinksheep/iso/pinksheep-AAAA.MM.JJ-x86_64.iso`.

**Installeur graphique :** Calamares n'est pas dans les dépôts officiels d'Arch. La **première** construction le compile depuis l'AUR, ce qui ajoute 10 à 20 minutes. Les suivantes le réutilisent.

| Option | Effet |
|---|---|
| `sudo ./build.sh --sans-graphique` | ISO plus légère, avec l'installeur texte seulement |
| `sudo ./build.sh --recompiler-calamares` | Force une nouvelle compilation de Calamares (après une mise à jour par exemple) |

Si la compilation échoue, l'ISO est quand même fabriquée, avec l'installeur texte seulement. Le message de fin indique ce qui est inclus.

> **Sans VM ?** Ça marche aussi dans WSL avec l'image Arch officielle (`wsl --install archlinux`), mais la VM est plus fiable.

## 2. Tester l'ISO (facultatif)

Tu peux démarrer l'ISO dans VirtualBox pour vérifier que **l'installeur** se lance, avec le menu de démarrage rose et le texte en français. Dans la VM, coche **Activer EFI**, mets 4 Go de RAM et un disque de 30 Go.

**Pour que le bureau Hyprland s'affiche dans la VM :** *Configuration → Affichage* → contrôleur **VMSVGA**, **Accélération 3D activée**, mémoire vidéo au maximum. Sans ça, Hyprland plante faute d'OpenGL. Sinon, choisis la session **« Hyprland (secours) »** sur l'écran de connexion : elle est plus lente mais marche partout.
⚠ Hyprland lui-même tourne très mal dans VirtualBox, faute de vraie accélération 3D. Le vrai test du bureau se fait sur ton PC.

## 3. Mettre l'ISO sur une clé USB

- **Ventoy** (recommandé) : installe Ventoy sur la clé une fois, puis copie juste le fichier `.iso` dessus.
- **Rufus** : choisis le mode **DD** quand il le demande.

## 4. Avant d'installer (important, sur le PC)

1. **Sauvegarde tes fichiers importants.** On touche aux disques.
2. **Désactive Secure Boot** dans le BIOS : l'ISO Arch ne le supporte pas.
3. **Désactive le démarrage rapide de Windows** (Panneau de configuration → Options d'alimentation → « Choisir l'action des boutons » → décocher « Activer le démarrage rapide »). Sinon le disque Windows peut être verrouillé.
4. **Choisis où va PinkSheep :**
   - **Idéal :** un deuxième disque (SSD) rien que pour PinkSheep.
   - **Sinon :** l'installeur graphique sait réduire Windows tout seul (*Installer à côté*). Pour plus de sécurité, tu peux aussi libérer la place toi-même depuis Windows (`diskmgmt.msc` → clic droit sur C: → *Réduire le volume*, au moins 100 Go), puis choisir l'espace libre dans l'installeur.
   - Débranche les disques que tu ne veux surtout pas toucher : c'est la sécurité la plus simple.

## 5. Installer

Démarre sur la clé (touche **F8**, **F11** ou **F12** au démarrage selon ta carte mère). Un menu PinkSheep s'affiche et lance tout seul l'**installeur graphique** au bout de 15 secondes :

```
1  Installeur graphique  (recommandé)
2  Installeur texte
3  Configurer le Wi-Fi
4  Terminal
5  Éteindre
```

**Internet est nécessaire** : le câble marche tout seul. Sans câble, l'installeur graphique ouvre lui-même l'**assistant Wi-Fi** : tu choisis ton réseau dans la liste et tu tapes le mot de passe (aussi disponible avec le choix **3**). PinkSheep télécharge ses paquets pendant l'installation.

L'installeur demande un **mot de passe administrateur séparé** de ton mot de passe, et 8 caractères minimum pour chacun.

### Installeur graphique (Calamares)

Des pages avec la souris et des boutons *Suivant* :

1. **Bienvenue** : vérifie l'espace disque, la RAM et internet.
2. **Langue et fuseau horaire** (France par défaut), puis **clavier** (AZERTY par défaut).
3. **Style** : *PinkSheep* ou *Hyprlust*.
4. **Partitions** :
   - **Installer à côté** : PinkSheep se met à côté de Windows. Un curseur permet de choisir la place de chacun. C'est **le bon choix pour un seul disque**.
   - **Effacer le disque** : seulement sur un disque vide ou dédié à PinkSheep.
   - **Partitionnement manuel** : pour les experts.
5. **Utilisateur** : ton nom, ton nom de connexion et ton mot de passe.
6. **Résumé** : vérifie bien le disque choisi, puis **Installer**.

L'installation installe la base Arch, puis la transforme en PinkSheep (pilotes NVIDIA, bureau, applis, thème, environ 3 Go à télécharger). Un diaporama montre les raccourcis pendant ce temps. À la fin, coche *Redémarrer maintenant* et retire la clé.

Si l'écran graphique ne démarre pas (rare, avec certaines cartes graphiques), le menu revient : prends alors l'installeur texte.

### Installeur texte (secours)

1. **archinstall** (base Arch) : l'écran récapitule quoi choisir. Le plus important :
   - Chargeur de démarrage **GRUB**
   - Profil **Minimal**
   - Réseau **NetworkManager**
   - Ton compte avec **sudo**
   - **À la fin, choisis « Exit archinstall », PAS « Reboot ».**
2. **Étape 2 PinkSheep** (automatique) : choix du style, puis pilotes, bureau, applis et thème.
3. Redémarre, retire la clé, choisis PinkSheep dans le menu, connecte-toi, et appuie sur **SUPER + H**.

Si tu as redémarré trop tôt : relance la clé, choix **4** (terminal), monte ton système sur `/mnt` (les instructions s'affichent) puis tape `pinksheep-install --etape2`.

---

## Style Hyprlust

Pendant l'installation, PinkSheep te demande **quel style** tu veux : *PinkSheep* ou *Hyprlust*. Tu peux aussi changer plus tard, depuis un terminal :

```bash
pinksheep-hyprlust            # passer au style Hyprlust
pinksheep-hyprlust --annuler  # revenir au style PinkSheep
```

Ce que fait `pinksheep-hyprlust` :

1. **Télécharge le dépôt Hyprlust sur ton PC** (il n'est pas copié dans l'ISO : il n'a pas de licence, donc on ne le redistribue pas).
2. **Sauvegarde tes configs actuelles**, puis reprend celles de Hyprlust : barre (avec ses 20+ dispositions et styles), lanceur Rofi, notifications, menu d'extinction, Kitty, fastfetch, rmpc, Yazi, btop, zathura, Neovim, mpv, newsboat et l'écran de verrouillage.
3. **Traduit ses couleurs** : Hyprlust utilise wallust. PinkSheep convertit ses modèles pour matugen, donc **sa barre et son lanceur se recolorent aussi avec `SUPER + W`**.
4. **Remplace ses scripts écrits pour l'ancien Hyprland** (sélecteur de fond, flou, mode jeu, disposition…) par des versions compatibles avec Hyprland 0.57.
5. **Active ses réglages Hyprland** (disposition *master*, espacements fins, flou fort, animations en glissé) depuis `~/.config/hypr/style-hyprlust.lua`.

Raccourcis en plus avec ce style : `SUPER + ALT + W` (disposition de la barre), `SUPER + CTRL + W` (style de la barre), `SUPER + SHIFT + G` (mode jeu), `SUPER + ALT + B` (flou léger), `SUPER + SHIFT + J` (master ↔ dwindle).

Pas repris (spécifique au PC de l'auteur) : Spicetify, Seanime, Upscayl, streamrip, trakt-scrobbler, les thèmes GTK/Kvantum et son `.zshrc`. Le Zsh PinkSheep reste en place, avec l'invite Starship de Hyprlust.

---

## Mettre à jour PinkSheep

Une fois PinkSheep installé, **pas besoin de refaire d'ISO** pour l'améliorer.

Le plus simple : quand l'icône **󰚰** apparaît dans la barre (en rouge si une faille de sécurité est corrigée), clique dessus. Elle met à jour le système, PinkSheep et les applis Flatpak d'un coup. Elle vérifie toutes les heures (clic droit : vérifier maintenant).

À la main :

| Je veux… | Commande |
|---|---|
| Mettre à jour tout le système (Hyprland, noyau, applis, pilotes…) | `maj` |
| Récupérer la dernière version de PinkSheep (scripts, thèmes, configs…) | `pinksheep-maj` |
| Savoir s'il y a une nouvelle version | `pinksheep-maj --verifier` |
| Appliquer une version reçue en zip | `pinksheep-maj ~/Téléchargements/pinksheep.zip` |

`pinksheep-maj` fait une sauvegarde de tes configs, puis :
- remplace les fichiers que tu n'as jamais modifiés ;
- **garde ceux que tu as modifiés** et pose la nouvelle version à côté (`fichier.pinksheep-nouveau`), pour que tu compares ;
- ne touche jamais à `perso.lua`, `~/.zshrc.perso`, tes fonds d'écran ni tes couleurs ;
- installe les nouveaux paquets ajoutés à PinkSheep, en même temps qu'une mise à jour complète du système.

Les sauvegardes sont dans `~/.local/share/pinksheep/sauvegardes/`.

**Dépôt privé sur GitHub :** la première fois, connecte ton compte avec `gh auth login`, puis `gh auth setup-git`.

L'ISO ne sert plus qu'à installer PinkSheep sur un **autre** PC, ou à réinstaller de zéro.

---

## Les fenêtres à la souris

- **Barre des tâches** (en haut à gauche, après les bureaux) : une icône par fenêtre. Clic sur l'appli active = la réduire ; clic sur une autre = l'afficher (même réduite) ; clic du milieu = la fermer.
- **Boutons sur les fenêtres** (réduire / agrandir / fermer, comme sur Windows) : `pinksheep-boutons` dans un terminal du bureau, une seule fois (quelques minutes de compilation). Ils prennent les couleurs de ton fond d'écran. Les enlever : `pinksheep-boutons --off`.

## Installer des applis

- **Discover** (dans le lanceur) : la boutique d'applis Flatpak de Flathub, avec recherche, captures et avis.
- **Paquets Arch** : `installer nom-du-paquet` dans le terminal (chercher : `chercher mot-clé`).

## Sécurité

- **Pare-feu** (ufw) activé : tout ce qui sort est permis, rien n'entre sans y être invité. Pour une appli qui doit recevoir des connexions (KDE Connect par exemple) : `sudo ufw allow 1714:1764/udp` et `sudo ufw allow 1714:1764/tcp`.
- **Failles connues** : l'icône des mises à jour devient rouge quand une mise à jour en corrige une (`arch-audit` pour le détail).

## Personnaliser ta distro

| Je veux… | Fichier |
|---|---|
| Ajouter / retirer des applis | `overlay/airootfs/usr/share/pinksheep/paquets.txt` |
| Changer les raccourcis, les animations | `skel/.config/hypr/hyprland.lua` |
| Changer la barre du haut | `skel/.config/waybar/config.jsonc` et `style.css` |
| Ajouter des fonds d'écran à l'ISO | mets-les dans `wallpapers/` |
| Changer quelle couleur va où (ex. bordures plus vives) | `skel/.config/matugen/modeles/` |
| Couleurs plus douces / plus vives | `SCHEMA=` en haut de `bin/pinksheep-fond` (`scheme-vibrant` par défaut, `scheme-tonal-spot` plus doux) |
| Changer le lanceur | `skel/.config/rofi/pinksheep.rasi` |

Sur un PC où PinkSheep est déjà installé, une modification envoyée sur le dépôt s'applique avec `pinksheep-maj`. Pour une nouvelle ISO : `git pull` puis `sudo ./build.sh`.

**Sur le PC déjà installé**, tes réglages vont dans `~/.config/hypr/perso.lua` : ce fichier n'est jamais écrasé et passe après tout le reste. Hyprland recharge sa config dès que tu sauvegardes.

---

## Raccourcis essentiels

`SUPER` = touche Windows. La liste complète s'affiche avec **SUPER + H**.

| Raccourci | Action |
|---|---|
| `SUPER + Espace` | Lancer une appli |
| `SUPER + Entrée` | Terminal |
| `SUPER + W` | **Choisir un fond d'écran → nouveau thème** |
| `SUPER + SHIFT + W` | Fond au hasard |
| `SUPER + E` / `SUPER + SHIFT + E` | Fichiers (Dolphin) / fichiers dans le terminal (Yazi) |
| `SUPER + SHIFT + M` | Musique (rmpc) |
| `SUPER + Y` | YouTube dans le terminal |
| `SUPER + SHIFT + A` | Visualiseur audio (cava) |
| `SUPER + B` | Navigateur |
| `SUPER + Q` ou `ALT + F4` | Fermer la fenêtre |
| `SUPER + V` | Fenêtre flottante ↔ en tuile |
| `SUPER + F` / `SUPER + M` | Plein écran / agrandir |
| `SUPER + R` | Réduire la fenêtre (un clic sur son icône dans la barre la fait revenir) |
| `SUPER + flèches` | Changer de fenêtre |
| `SUPER + SHIFT + flèches` | Déplacer la fenêtre |
| `SUPER + 1…0` | Changer de bureau |
| `SUPER + SHIFT + 1…0` | Envoyer la fenêtre sur un bureau |
| `SUPER + clic gauche / droit` | Déplacer / redimensionner à la souris |
| `SUPER + SHIFT + S` | Capture d'écran d'une zone |
| `SUPER + SHIFT + V` | Historique du presse-papiers |
| `SUPER + N` | Notifications |
| `SUPER + L` | Verrouiller |
| `SUPER + Échap` | Éteindre / redémarrer |

Dans le terminal : `y` ouvre Yazi (et te laisse dans le dossier où tu l'as quitté), `z dossier` saute vers un dossier déjà visité, `Ctrl+R` cherche dans l'historique, `maj` met tout le système à jour.

**Musique :** mets tes fichiers audio dans le dossier `Musique`, puis `SUPER + SHIFT + M`.

---

## En cas de souci

| Problème | Solution |
|---|---|
| Windows n'apparaît pas dans le menu de démarrage | Une fois dans PinkSheep : `sudo grub-mkconfig -o /boot/grub/grub.cfg` |
| Le démarrage reste bloqué sur l'écran de chargement | Appuie sur **Échap** pour voir les messages du système. Pour revenir aux messages à chaque démarrage : `sudo pinksheep-chargement --off` |
| Le terminal s'ouvre puis se ferme aussitôt | Kitty a besoin d'OpenGL 3.3. PinkSheep bascule alors tout seul sur **foot**, un terminal sans accélération graphique, avec les mêmes couleurs |
| Écran noir après la connexion | Sur l'écran de connexion, choisis la session **« Hyprland (secours) »** : rendu logiciel, sans effets, mais le bureau s'affiche et tu peux réparer |
| Écran noir après la connexion (NVIDIA) | `CTRL+ALT+F3` pour avoir une console, connecte-toi, puis regarde `cat /etc/pinksheep/gpu` (doit dire `nvidia`) et `nvidia-smi` |
| Une config est cassée | `sudo pinksheep-setup --forcer-config` remet tout d'origine (sauvegarde automatique de l'ancienne config, `perso.lua` conservé) |
| Une appli de `paquets.txt` manquait | Le journal `/var/log/pinksheep-setup.log` liste les paquets ignorés |
| Les couleurs n'ont pas changé dans une appli | Les applis GTK/Qt (Dolphin, Firefox…) prennent les nouvelles couleurs à leur prochain lancement |
| Erreur dans la config Hyprland | Un bandeau rouge s'affiche en haut. Si plus aucun raccourci ne marche : `SUPER+Q` ouvre un terminal de secours |

---

## Bon à savoir

- PinkSheep reste une **Arch** : mises à jour avec `sudo pacman -Syu`, et tout le [wiki Arch](https://wiki.archlinux.org) s'applique.
- Le nom « Arch Linux » est une marque : PinkSheep se présente comme « basé sur Arch », jamais comme « Arch ».
- Configs écrites pour **Hyprland 0.57** (config en Lua). La doc officielle : https://wiki.hypr.land
- Le style Hyprlust appartient à son auteur, Nischal Dawadi (scripts basés sur [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots), GPL-3). PinkSheep le télécharge depuis GitHub au lieu de l'embarquer.
- Inspiré du setup « Hyprlust » (vidéo *Hyprland Rice : When Aesthetics Meets Productivity*), refait de zéro pour PinkSheep. Les couleurs viennent de **matugen** (dépôts officiels Arch) et les transitions de fond d'écran de **awww**.
