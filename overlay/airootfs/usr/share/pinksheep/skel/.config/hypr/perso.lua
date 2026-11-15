-- ╭────────────────────────────────────────────────────────────╮
-- │  Tes réglages perso. Ce fichier n'est jamais écrasé par     │
-- │  les mises à jour de PinkSheep. Il passe après hyprland.lua. │
-- ╰────────────────────────────────────────────────────────────╯

-- Exemples (enlève les « -- » devant une ligne pour l'activer) :

-- Écran 1080p à 144 Hz :
-- hl.monitor({ output = "", mode = "1920x1080@144", position = "auto", scale = 1 })

-- Moins d'espace entre les fenêtres :
-- hl.config({ general = { gaps_in = 3, gaps_out = 6 } })

-- Pas de transparence sur les fenêtres inactives :
-- hl.config({ decoration = { inactive_opacity = 1.0 } })

-- Ton propre raccourci (SUPER + O pour ouvrir OBS) :
-- hl.bind("SUPER + O", hl.dsp.exec_cmd("obs"), { description = "Ouvrir OBS" })

-- Lancer une appli au démarrage :
-- hl.on("hyprland.start", function() hl.exec_cmd("discord") end)
