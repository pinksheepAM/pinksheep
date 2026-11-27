#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  PinkSheep — tests de la session Caelestia                    │
# │  À lancer en utilisateur, de préférence DANS la session       │
# │  Caelestia (certains tests ne s'y font que là).               │
# ╰──────────────────────────────────────────────────────────────╯
OK=0; KO=0
ok() { printf '  [ok] %s\n' "$1"; OK=$((OK + 1)); }
ko() { printf '  [X]  %s\n' "$1"; KO=$((KO + 1)); }
t()  { local nom="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$nom"; else ko "$nom"; fi; }

echo ":: Composants"
t "Caelestia en état de marche (vérificateur)" pinksheep-caelestia-verifier
t "Quickshell compatible avec Qt"               qs --private-check-compat
t "Python : caelestia + materialyoucolor"       python3 -c 'import caelestia, materialyoucolor'
t "« caelestia install » est bien bloqué"       bash -c '! caelestia install'
t "« caelestia update » est bien bloqué"        bash -c '! caelestia update'

echo ":: Configuration"
pinksheep-caelestia-preparer
t "Config Hyprland Caelestia sans erreur"       Hyprland --verify-config -c /usr/share/pinksheep/caelestia/hypr/hyprland.lua
t "Config Hyprland classique sans erreur"       Hyprland --verify-config
t "Réglages PinkSheep en place"                 test -f "$HOME/.config/caelestia/hypr-user.lua"
t "Couleurs : fichier de départ présent"        test -f "$HOME/.config/hypr/scheme/current.lua"
t "Session Caelestia à l'écran de connexion"    test -f /usr/share/wayland-sessions/pinksheep-caelestia.desktop
t "Session classique à l'écran de connexion"    test -f /usr/share/wayland-sessions/pinksheep-classique.desktop

if [[ "${PINKSHEEP_SESSION:-}" == caelestia ]]; then
    echo ":: Dans la session Caelestia"
    t "Le shell tourne"                         bash -c '[[ $(qs -c caelestia list -j | jq length) -gt 0 ]]'
    t "Le garde-fou tourne"                     pgrep -f pinksheep-caelestia-garde
    t "Un seul service de notifications (pas SwayNC)" bash -c '! pgrep -x swaync'
    t "Pas de Waybar en double"                 bash -c '! pgrep -x waybar'
    t "Couleurs du terminal générées"           test -s "$HOME/.local/state/caelestia/theme/kitty-couleurs.conf"
    t "Lien des couleurs Kitty valide"          test -s "$HOME/.config/kitty/couleurs.conf"
    t "Couleurs Qt générées"                    test -s "$HOME/.local/state/caelestia/theme/qt6ct-pinksheep.conf"
    t "Clavier en disposition PinkSheep"        bash -c "hyprctl getoption input:kb_layout -j | jq -r .str | grep -qv '^us$'"
else
    echo "   (ouvre la session « PinkSheep (Caelestia) » et relance ce script pour les tests en session)"
fi

echo
echo "Résultat : $OK réussi(s), $KO échoué(s)"
cat <<'MANUEL'

À vérifier à la main (5 minutes) :
  [ ] SUPER seul ouvre le lanceur ; SUPER + Entrée ouvre Kitty
  [ ] SUPER + & / é / " … change de bureau (AZERTY)
  [ ] SUPER + H ouvre l'aide PinkSheep ; SUPER + I ouvre les paramètres
  [ ] Changer de fond d'écran recolore la barre, Kitty et une appli Qt (Dolphin)
  [ ] Verrouillage (SUPER + L) puis déverrouillage avec le mot de passe
  [ ] Notification de test : notify-send Test Bonjour
  [ ] Panne simulée : « caelestia shell -k » trois fois en moins de 10 min
      → la barre classique prend le relais avec un message
  [ ] Steam lance un jeu, puis retour au bureau sans souci
MANUEL
((KO == 0))
