-- PinkSheep : ajouts à la config Caelestia, chargés en dernier.
-- Ce fichier est à toi : pinksheep-maj ne l'écrase jamais.
local fn   = require("utils.functions")
local home = os.getenv("HOME")

-- Clavier : la même disposition que la session classique (écrite à l'installation)
local clavier = home .. "/.config/hypr/clavier.lua"
local f = io.open(clavier)
if f then
    f:close()
    dofile(clavier)
else
    hl.config({ input = { kb_layout = "fr" } })
end
hl.config({ input = { numlock_by_default = true } })

-- Thème des applis Qt : celui de PinkSheep (Caelestia attend qtengine, absent ici)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Bureaux 1 à 10 en AZERTY : codes de touches (code:10 = touche « 1/& »)
for i = 1, 10 do
    local touche = "code:" .. (9 + i)
    hl.bind("SUPER + " .. touche,         fn.wsaction("focus", "", i))
    hl.bind("SUPER + SHIFT + " .. touche, fn.wsaction("move", "", i))
    hl.bind("SUPER + ALT + " .. touche,   fn.wsaction("move", "", i))
end

-- Raccourcis PinkSheep
hl.bind("SUPER + H", hl.dsp.exec_cmd("pinksheep-aide"))
hl.bind("SUPER + I", hl.dsp.global("caelestia:nexus"))   -- Paramètres (comme Windows + I)
hl.bind("SUPER + W", hl.dsp.global("caelestia:nexus"))   -- page « Fond d'écran et style »

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("pinksheep-caelestia-garde")
    -- Verr. Maj / Verr. Num à l'écran (le volume et la luminosité : affichage de Caelestia)
    hl.exec_cmd("swayosd-server")
end)
