-- ╭──────────────────────────────────────────────────────────────╮
-- │  Style « Hyprlust » porté pour Hyprland 0.57 (Lua)            │
-- │  D'après les réglages de github.com/NischalDawadi/Hyprlust    │
-- │  Activé par : pinksheep-hyprlust   (désactivé : --annuler)    │
-- ╰──────────────────────────────────────────────────────────────╯

hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 6,
        border_size      = 2,
        resize_on_border = false,
        layout           = "master",
    },
    master = {
        new_status = "master",
        new_on_top = true,
        mfact      = 0.5,
    },
    dwindle = {
        special_scale_factor = 0.8,
    },
    decoration = {
        rounding           = 10,
        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,
        dim_inactive       = false,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            noise             = 0.02,
            vibrancy          = 0.1796,
            ignore_opacity    = true,
            new_optimizations = true,
            special           = true,
            popups            = true,
        },
    },
})

-- Animations Hyprlust : glissements et « popin » avec une courbe easeOut
hl.curve("hlDefault", { type = "bezier", points = { {0, 1},    {0, 1}   } })
hl.curve("hlEaseOut", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
local vitesse = 6.9
hl.animation({ leaf = "windows",     enabled = true, speed = vitesse, bezier = "hlEaseOut", style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = vitesse, bezier = "hlEaseOut", style = "popin 90%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = vitesse, bezier = "hlEaseOut", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = vitesse, bezier = "hlEaseOut", style = "slide" })
hl.animation({ leaf = "fade",        enabled = true, speed = 10,      bezier = "hlDefault" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 10,      bezier = "hlEaseOut", style = "slide" })
hl.animation({ leaf = "layers",      enabled = true, speed = vitesse, bezier = "hlEaseOut", style = "slide" })

-- Raccourcis en plus, comme dans Hyprlust
hl.bind("SUPER + SHIFT + J", hl.dsp.exec_cmd("~/.config/hypr/scripts/ChangeLayout.sh"), { description = "Disposition master ↔ dwindle" })
hl.bind("SUPER + ALT + B",   hl.dsp.exec_cmd("~/.config/hypr/scripts/ChangeBlur.sh"),   { description = "Flou fort ↔ léger" })
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/GameMode.sh"),     { description = "Mode jeu (sans effets)" })
hl.bind("SUPER + ALT + W",   hl.dsp.exec_cmd("~/.config/hypr/scripts/WaybarLayout.sh"), { description = "Changer la disposition de la barre" })
hl.bind("SUPER + CTRL + W",  hl.dsp.exec_cmd("~/.config/hypr/scripts/WaybarStyles.sh"), { description = "Changer le style de la barre" })
