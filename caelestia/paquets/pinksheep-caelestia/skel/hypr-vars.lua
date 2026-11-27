-- PinkSheep : réglages de la session Caelestia.
-- Ce fichier est à toi : pinksheep-maj ne l'écrase jamais.
-- Liste complète des variables : /usr/share/pinksheep/caelestia/hypr/variables.lua
return {
    -- Applis de PinkSheep
    terminal        = "pinksheep-terminal",
    browser         = "firefox",
    editor          = "kate",
    fileExplorer    = "dolphin",
    audioSettings   = "pavucontrol",

    -- Curseur de PinkSheep (celui de Caelestia est sur l'AUR)
    cursorTheme     = "breeze_cursors",

    -- Pas d'hibernation configurée sur PinkSheep : simple mise en veille
    sleepGestureCmd = "systemctl suspend",

    -- Raccourcis : on garde les habitudes PinkSheep
    kbTerminal      = { "SUPER + Return", "SUPER + T" },
    kbBrowser       = "SUPER + B",
}
