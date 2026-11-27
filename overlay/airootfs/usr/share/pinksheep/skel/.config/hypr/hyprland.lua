-- ╭──────────────────────────────────────────────────────────────╮
-- │  PinkSheep — configuration Hyprland (format Lua, 0.57+)       │
-- │                                                              │
-- │  Ce fichier est rechargé automatiquement à chaque sauvegarde. │
-- │  Tes réglages perso vont plutôt dans  perso.lua  (à côté) :   │
-- │  ils passent APRÈS ce fichier, donc ils ont le dernier mot.   │
-- │                                                              │
-- │  Aide-mémoire des raccourcis :  SUPER + H                     │
-- │  Changer de fond (et donc de couleurs) :  SUPER + W           │
-- │  Doc officielle : https://wiki.hypr.land/configuring/         │
-- ╰──────────────────────────────────────────────────────────────╯


-- Les couleurs ne sont PAS ici : elles sont générées automatiquement à partir
-- du fond d'écran (SUPER + W pour en changer) dans couleurs.lua.


--------------------
---- PROGRAMMES ----
--------------------
local terminal     = "pinksheep-terminal"   -- Kitty, ou foot si Kitty ne peut pas démarrer
local fichiers     = "dolphin"
local navigateur   = "firefox"
local lanceur      = "rofi -show drun"
local fichiers_tui = terminal .. " --class pinksheep-yazi yazi"
local mainMod      = "SUPER"   -- la touche Windows


------------------
---- ÉCRANS ----
------------------
-- "preferred" = meilleure résolution/fréquence que l'écran annonce.
-- Pour forcer par ex. 1920x1080 à 144 Hz :  mode = "1920x1080@144"
-- Liste de tes écrans :  hyprctl monitors
local function gpu_detecte()
    local f = io.open("/etc/pinksheep/gpu", "r")
    if not f then return "" end
    local v = f:read("*l") or ""
    f:close()
    return v
end

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    -- En machine virtuelle, l'échelle automatique se trompe souvent (×2) : on force 1
    scale    = (gpu_detecte() == "vm") and 1 or "auto",
})


----------------------------------
---- VARIABLES D'ENVIRONNEMENT ----
----------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "breeze_cursors")
-- Thème des applis Qt/KDE (Dolphin…). « qt5ct » sert aux applis Qt 5 (qt5ct)
-- ET Qt 6 (qt6ct répond aussi à ce nom) : les deux prennent le style Kvantum PinkSheep.
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("XDG_MENU_PREFIX", "arch-")             -- répare le menu « Ouvrir avec » de Dolphin
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto") -- Discord, VS Code… en Wayland natif

-- LibreOffice en mode Qt 6 : il prend le même style (Kvantum) que Dolphin, Okular…
-- Seulement si le module Qt 6 de LibreOffice est présent (sinon il choisit seul).
local f_lo = io.open("/usr/lib/libreoffice/program/libvclplug_qt6lo.so", "r")
if f_lo then
    f_lo:close()
    hl.env("SAL_USE_VCLPLUGIN", "qt6")
end

-- NVIDIA : le script d'installation écrit "nvidia" dans ce fichier si besoin.
local function lire_gpu()
    local f = io.open("/etc/pinksheep/gpu", "r")
    if not f then return "" end
    local v = f:read("*l") or ""
    f:close()
    return v
end

if lire_gpu() == "nvidia" then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
end


-------------------
---- DÉMARRAGE ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("pinksheep-fond --restaurer")   -- remet le dernier fond + ses couleurs
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swaync")
    hl.exec_cmd("swayosd-server")          -- affichage à l'écran : volume, luminosité, Verr. Maj
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("pinksheep-theme; mpd")    -- thème GTK/icônes, puis serveur de musique (rmpc)
    hl.exec_cmd("pinksheep-bienvenue")     -- uniquement au tout premier lancement
end)


-----------------------
---- APPARENCE ----
-----------------------
hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 12,
        border_size = 2,

        col = {
            -- valeurs de secours ; les vraies couleurs viennent de couleurs.lua
            active_border   = { colors = { "rgba(ff7eb6ee)", "rgba(c8a2ffee)" }, angle = 45 },
            inactive_border = "rgba(3a2a40aa)",
        },

        -- Redimensionner en tirant sur les bords avec la souris (comme sous Windows)
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.95,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = 0x55000000,
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            vibrancy = 0.17,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Animations (reprises de la config officielle, un poil plus douces)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slide" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- Couleurs générées depuis le fond d'écran (bordures, ombres, groupes)
pcall(require, "couleurs")

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = 0,     -- pas de fond d'écran Hyprland par défaut
        disable_hyprland_logo   = true,
        focus_on_activate       = true,
    },
    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
})


-----------------
---- CLAVIER / SOURIS ----
-----------------
hl.config({
    input = {
        kb_layout          = "fr",   -- remplacé par clavier.lua (généré à l'installation)
        kb_variant         = "",
        numlock_by_default = true,
        follow_mouse       = 1,
        sensitivity        = 0,      -- -1.0 à 1.0
        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Disposition clavier détectée à l'installation (fr, be, ch, us…)
pcall(require, "clavier")

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


----------------------
---- RACCOURCIS ----
----------------------
-- Chaque raccourci a une description : c'est elle qui s'affiche dans SUPER + H.
local function bind(touches, action, description, options)
    options = options or {}
    options.description = description
    hl.bind(touches, action, options)
end

-- Applications
bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal),   "Ouvrir le terminal")
bind(mainMod .. " + T",      hl.dsp.exec_cmd(terminal),   "Ouvrir le terminal")
bind(mainMod .. " + E",      hl.dsp.exec_cmd(fichiers),   "Ouvrir les fichiers (Dolphin)")
bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(fichiers_tui), "Fichiers dans le terminal (Yazi)")
bind(mainMod .. " + B",      hl.dsp.exec_cmd(navigateur), "Ouvrir le navigateur")
bind(mainMod .. " + space",  hl.dsp.exec_cmd(lanceur),    "Lanceur d'applications")
bind(mainMod .. " + D",      hl.dsp.exec_cmd(lanceur),    "Lanceur d'applications")
bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd(terminal .. " --class pinksheep-btop btop"), "Gestionnaire des tâches")

-- Fond d'écran & thème (les couleurs de tout le bureau suivent le fond)
bind(mainMod .. " + W",         hl.dsp.exec_cmd("pinksheep-fond --choisir"),  "Choisir un fond d'écran")
bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("pinksheep-fond --aleatoire"), "Fond d'écran au hasard")

-- Musique & vidéo dans le terminal
bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(terminal .. " --class pinksheep-musique rmpc"), "Musique (rmpc)")
bind(mainMod .. " + Y",         hl.dsp.exec_cmd(terminal .. " --class pinksheep-yt pinksheep-yt"), "YouTube dans le terminal")
bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd(terminal .. " --class pinksheep-cava cava"), "Visualiseur audio (cava)")
bind(mainMod .. " + A",         hl.dsp.exec_cmd("pinksheep-ia"),         "Assistant IA PinkSheep")

-- Aide & système
bind(mainMod .. " + H",           hl.dsp.exec_cmd("pinksheep-aide"),          "Afficher cette aide")
bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("pinksheep-power"),         "Menu éteindre / redémarrer / veille")
bind(mainMod .. " + L",           hl.dsp.exec_cmd("loginctl lock-session"),  "Verrouiller l'écran")
bind(mainMod .. " + N",           hl.dsp.exec_cmd("swaync-client -t -sw"),   "Centre de notifications")
bind(mainMod .. " + SHIFT + V",   hl.dsp.exec_cmd("pinksheep-presse-papiers"), "Historique du presse-papiers")
bind(mainMod .. " + SHIFT + C",   hl.dsp.exec_cmd("hyprpicker -a"),          "Pipette à couleur")
bind(mainMod .. " + SHIFT + R",   hl.dsp.reload_config(),                    "Recharger la config Hyprland")
bind(mainMod .. " + SHIFT + B",   hl.dsp.exec_cmd("pkill waybar; waybar"),   "Relancer la barre (Waybar)")

-- Captures d'écran (enregistrées dans Images/Captures)
bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("pinksheep-capture zone"),   "Capture d'une zone")
bind("Print",                   hl.dsp.exec_cmd("pinksheep-capture zone"),   "Capture d'une zone")
bind("SHIFT + Print",           hl.dsp.exec_cmd("pinksheep-capture ecran"),  "Capture de tout l'écran")

-- Fenêtres
bind(mainMod .. " + Q",       hl.dsp.window.close(),                            "Fermer la fenêtre")
bind("ALT + F4",              hl.dsp.window.close(),                            "Fermer la fenêtre")
bind(mainMod .. " + F",       hl.dsp.window.fullscreen({ action = "toggle" }),  "Plein écran")
bind(mainMod .. " + M",       hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }), "Agrandir (garde la barre)")
bind(mainMod .. " + V",       hl.dsp.window.float({ action = "toggle" }),       "Fenêtre flottante ↔ en tuile")
bind(mainMod .. " + C",       hl.dsp.window.center(),                           "Centrer la fenêtre flottante")
bind(mainMod .. " + P",       hl.dsp.window.pseudo(),                           "Pseudo-tuile")
bind(mainMod .. " + J",       hl.dsp.layout("togglesplit"),                     "Changer le sens de découpe")
bind(mainMod .. " + G",       hl.dsp.group.toggle(),                            "Grouper en onglets")
bind(mainMod .. " + Tab",     hl.dsp.group.next(),                              "Onglet suivant du groupe")
bind("ALT + Tab",             hl.dsp.window.cycle_next(),                       "Fenêtre suivante")

-- Focus et déplacement avec les flèches
local directions = { left = "de gauche", right = "de droite", up = "du haut", down = "du bas" }
for fleche, nom in pairs(directions) do
    bind(mainMod .. " + " .. fleche,         hl.dsp.focus({ direction = fleche }),       "Aller à la fenêtre " .. nom)
    bind(mainMod .. " + SHIFT + " .. fleche, hl.dsp.window.swap({ direction = fleche }), "Échanger avec la fenêtre " .. nom)
end

-- Redimensionner au clavier (maintenir)
bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x =  40, y =   0, relative = true }), "Élargir la fenêtre",   { repeating = true })
bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y =   0, relative = true }), "Rétrécir la fenêtre",  { repeating = true })
bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x =   0, y =  40, relative = true }), "Agrandir en hauteur",  { repeating = true })
bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x =   0, y = -40, relative = true }), "Réduire en hauteur",   { repeating = true })

-- Bureaux virtuels 1 à 10.
-- On utilise les codes de touches (code:10 = touche « 1/& ») pour que ça marche
-- aussi bien en AZERTY qu'en QWERTY.
for i = 1, 10 do
    local touche = "code:" .. (9 + i)
    bind(mainMod .. " + " .. touche,         hl.dsp.focus({ workspace = i }),       "Aller au bureau " .. i)
    bind(mainMod .. " + SHIFT + " .. touche, hl.dsp.window.move({ workspace = i }), "Envoyer la fenêtre au bureau " .. i)
end

bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Bureau suivant (molette)")
bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), "Bureau précédent (molette)")

-- Bureau « tiroir » : un bureau caché qu'on fait apparaître par-dessus
bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("tiroir"),          "Afficher / cacher le tiroir")
bind(mainMod .. " + SHIFT + D", hl.dsp.window.move({ workspace = "special:tiroir" }), "Ranger la fenêtre dans le tiroir")
-- Réduire : la fenêtre disparaît mais reste dans la barre des tâches (un clic l'y fait revenir)
bind(mainMod .. " + R", hl.dsp.window.move({ workspace = "special:reduites", follow = false }), "Réduire la fenêtre")

-- Souris : SUPER + clic gauche = déplacer, SUPER + clic droit = redimensionner
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   "Déplacer la fenêtre (souris)",      { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), "Redimensionner la fenêtre (souris)", { mouse = true })

-- Touches multimédia (fonctionnent même écran verrouillé), avec affichage à l'écran (SwayOSD)
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5 --max-volume 100"), "Volume +",  { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"),                "Volume −",  { locked = true, repeating = true })
bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),     "Couper le son", { locked = true })
bind("XF86AudioMicMute",     hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),      "Couper le micro", { locked = true })
bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("swayosd-client --brightness +5"), "Luminosité +", { locked = true, repeating = true })
bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("swayosd-client --brightness -5"), "Luminosité −", { locked = true, repeating = true })
bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       "Piste suivante",   { locked = true })
bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   "Piste précédente", { locked = true })
bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), "Lecture / pause",  { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Lecture / pause",  { locked = true })


-------------------------------
---- RÈGLES DE FENÊTRES ----
-------------------------------
-- Les petites fenêtres de réglages s'ouvrent en flottant, centrées
hl.window_rule({
    name   = "reglages-flottants",
    match  = { class = "^(org.pulseaudio.pavucontrol|pavucontrol|blueman-manager|nm-connection-editor|nwg-look|qt6ct|org.kde.ark)$" },
    float  = true,
    center = true,
    size   = "900 600",
})

-- Boîtes de dialogue « Ouvrir / Enregistrer »
hl.window_rule({
    name   = "dialogues-fichiers",
    match  = { title = "^(Ouvrir.*|Enregistrer.*|Open.*|Save.*|Choisir.*|Sélectionner.*)$" },
    float  = true,
    center = true,
})

-- Aide-mémoire et gestionnaire des tâches
hl.window_rule({
    name   = "assistant-ia",
    match  = { class = "^(pinksheep-ia)$" },
    float  = true,
    center = true,
    size   = "620 520",
})
hl.window_rule({
    name   = "aide-pinksheep",
    match  = { class = "^(pinksheep-aide|pinksheep-btop|pinksheep-maj)$" },
    float  = true,
    center = true,
    size   = "1000 700",
})

-- Musique, YouTube et visualiseur : fenêtres flottantes
hl.window_rule({
    name   = "terminal-multimedia",
    match  = { class = "^(pinksheep-musique|pinksheep-yt)$" },
    float  = true,
    center = true,
    size   = "1100 650",
})
hl.window_rule({
    name   = "cava",
    match  = { class = "^(pinksheep-cava)$" },
    float  = true,
    size   = "900 300",
    move   = "40 monitor_h-340",
    pin    = true,
})

-- Éditeur de captures d'écran
hl.window_rule({
    name  = "satty",
    match = { class = "^(com.gabm.satty)$" },
    float = true,
    center = true,
})

-- Vidéo en incrustation (Firefox) : flottante, sur tous les bureaux
hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture|Incrustation vidéo)$" },
    float = true,
    pin   = true,
})

-- Les jeux Steam : pas d'animation d'ouverture, contenu « jeu »
hl.window_rule({
    name    = "jeux-steam",
    match   = { class = "^(steam_app_.*)$" },
    content = "game",
    no_anim = true,
})

-- Ignore les demandes « agrandir » des applis (évite des tailles bizarres)
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Corrige le glisser-déposer de certaines applis XWayland
hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Flou derrière la barre, le lanceur et les notifications
hl.layer_rule({ name = "flou-waybar", match = { namespace = "^waybar$" },  blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "flou-rofi",   match = { namespace = "^rofi$" },    blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "flou-wlogout", match = { namespace = "^logout_dialog$" }, blur = true })
hl.layer_rule({ name = "flou-notifs", match = { namespace = "^swaync-(control-center|notification-window)$" }, blur = true, ignore_alpha = 0.2 })


-- Session de secours (rendu logiciel) : on coupe les effets coûteux
if os.getenv("PINKSHEEP_SECOURS") == "1" then
    hl.config({
        animations = { enabled = false },
        decoration = { blur = { enabled = false }, shadow = { enabled = false } },
    })
end


---------------------------------------
---- STYLE (PinkSheep ou Hyprlust) ----
---------------------------------------
-- « pinksheep-hyprlust » écrit "hyprlust" dans ~/.config/pinksheep/style
local function style_choisi()
    local f = io.open((os.getenv("HOME") or "") .. "/.config/pinksheep/style", "r")
    if not f then return "pinksheep" end
    local v = f:read("*l") or "pinksheep"
    f:close()
    return v
end

if style_choisi() == "hyprlust" then
    pcall(require, "style-hyprlust")
end


-- Réduire / agrandir / fermer à la souris (barre des tâches, boutons des fenêtres)
pcall(require, "fenetres")


----------------------------
---- RÉGLAGES PERSO ----
----------------------------
-- Tout ce que tu mets dans perso.lua passe en dernier et écrase ce qui précède.
pcall(require, "perso")
