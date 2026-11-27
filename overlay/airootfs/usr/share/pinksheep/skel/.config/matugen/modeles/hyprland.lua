-- Généré automatiquement par matugen à partir du fond d'écran. Ne pas modifier :
-- ce fichier est réécrit à chaque changement de fond (SUPER + W).
hl.config({
    general = {
        col = {
            active_border   = { colors = { "rgba({{colors.primary.default.hex_stripped}}ee)", "rgba({{colors.tertiary.default.hex_stripped}}ee)" }, angle = 45 },
            inactive_border = "rgba({{colors.surface_container_highest.default.hex_stripped}}aa)",
        },
    },
    decoration = {
        shadow = {
            color = 0x55{{colors.primary_container.default.hex_stripped}},
        },
    },
    group = {
        col = {
            border_active   = "rgba({{colors.secondary.default.hex_stripped}}ee)",
            border_inactive = "rgba({{colors.surface_container_high.default.hex_stripped}}aa)",
        },
    },
})

-- Couleurs des barres de titre des fenêtres (fenetres.lua, boutons hyprbars)
pinksheep_couleurs = {
    barre    = "rgba({{colors.surface_container.default.hex_stripped}}ee)",
    texte    = "rgb({{colors.on_surface.default.hex_stripped}})",
    fermer   = "rgb({{colors.primary.default.hex_stripped}})",
    agrandir = "rgb({{colors.tertiary.default.hex_stripped}})",
    reduire  = "rgb({{colors.secondary.default.hex_stripped}})",
    symbole  = "rgb({{colors.on_primary.default.hex_stripped}})",
}
