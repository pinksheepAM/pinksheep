-- PinkSheep — réduire, agrandir et fermer les fenêtres à la souris
--
-- Hyprland ne sait pas « réduire » une fenêtre : PinkSheep la range dans un
-- bureau caché (« reduites »). Elle ressort quand on clique sur son icône
-- dans la barre des tâches, ou quand une appli demande à s'afficher.
-- (Ce fichier est mis à jour par pinksheep-maj : tes réglages vont dans perso.lua.)

local REDUITES = "special:reduites"

-- Raison de focus « une appli / la barre des tâches demande à afficher la fenêtre »
-- (Desktop::FOCUS_REASON_DESKTOP_STATE_CHANGE dans Hyprland 0.57)
local DEMANDE_AFFICHAGE = 128

local function est_reduite(w)
    local ws = w and w.workspace
    if not ws or not ws.special then return false end
    return ws.name == REDUITES or ws.name == "reduites" or ws.addressable_name == REDUITES
end

-- Plus tard, hors de l'évènement en cours (Hyprland n'aime pas qu'on déplace
-- une fenêtre pendant qu'il est en train de la mettre au premier plan)
local function plus_tard(action)
    hl.timer(action, { timeout = 1, type = "oneshot" })
end

local function reduire(w)
    if not w or est_reduite(w) then return end
    local adresse = "address:" .. w.address
    plus_tard(function()
        hl.dispatch(hl.dsp.window.move({ workspace = REDUITES, follow = false, window = adresse }))
    end)
end

local function ressortir(w)
    if not est_reduite(w) then return end
    local adresse = "address:" .. w.address
    local ecran   = w.monitor and w.monitor.name
    plus_tard(function()
        -- vers le bureau affiché sur son écran, et au premier plan
        if ecran then
            hl.dispatch(hl.dsp.window.move({ monitor = ecran, window = adresse }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = "m+0", window = adresse }))
        end
        hl.dispatch(hl.dsp.focus({ window = adresse }))
        -- s'il reste d'autres fenêtres réduites, leur bureau caché ne doit pas rester ouvert
        local special = hl.get_active_special_workspace(ecran)
        if special and (special.name == REDUITES or special.name == "reduites") then
            hl.dispatch(hl.dsp.workspace.toggle_special("reduites"))
        end
    end)
end

-- Barre des tâches (clic sur l'appli active) et boutons « réduire » des applis
hl.on("window.minimize", function(w, demande)
    if demande then reduire(w) else ressortir(w) end
end)

-- Clic sur une appli réduite dans la barre des tâches : elle revient
hl.on("window.active", function(w, raison)
    if raison == DEMANDE_AFFICHAGE then ressortir(w) end
end)

-------------------------------------------------------------------------------
-- Boutons sur les fenêtres (module officiel hyprbars, installé par
-- « pinksheep-boutons »). Sans le module, cette partie ne fait rien.
-------------------------------------------------------------------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("pinksheep-boutons --charger")   -- ne fait rien si les boutons ne sont pas installés
end)

if hl.plugin and hl.plugin.hyprbars then
    local c = pinksheep_couleurs or {}
    local agrandir = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']]

    hl.config({
        plugin = {
            hyprbars = {
                bar_height                 = 30,
                bar_color                  = c.barre or "rgba(1e1223ee)",
                col                        = { text = c.texte or "rgb(f3e4ee)" },
                bar_text_font              = "Noto Sans",
                bar_text_size              = 10,
                bar_text_weight            = "medium",
                bar_text_align             = "center",
                bar_padding                = 12,
                bar_button_padding         = 9,
                bar_part_of_window         = true,
                bar_precedence_over_border = true,
                icon_on_hover              = true,
                on_double_click            = agrandir,
            },
        },
    })

    -- De droite à gauche : fermer, agrandir, réduire (des pastilles, le symbole apparaît au survol)
    hl.plugin.hyprbars.add_button({
        bg_color = c.fermer or "rgb(ff7eb6)", fg_color = c.symbole or "rgb(2a1830)", size = 14, icon = "×",
        action = [[hyprctl dispatch 'hl.dsp.window.close()']],
    })
    hl.plugin.hyprbars.add_button({
        bg_color = c.agrandir or "rgb(c8a2ff)", fg_color = c.symbole or "rgb(2a1830)", size = 14, icon = "+",
        action = agrandir,
    })
    hl.plugin.hyprbars.add_button({
        bg_color = c.reduire or "rgb(ffd6e8)", fg_color = c.symbole or "rgb(2a1830)", size = 14, icon = "−",
        action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:reduites", follow = false })']],
    })
end
