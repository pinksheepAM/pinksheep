-- Généré automatiquement par matugen : thème Neovim aux couleurs du fond d'écran
local c = {
  fond      = "{{colors.surface.default.hex}}",
  fond2     = "{{colors.surface_container.default.hex}}",
  fond3     = "{{colors.surface_container_high.default.hex}}",
  texte     = "{{colors.on_surface.default.hex}}",
  discret   = "{{colors.on_surface_variant.default.hex}}",
  contour   = "{{colors.outline.default.hex}}",
  primaire  = "{{colors.primary.default.hex}}",
  second    = "{{colors.secondary.default.hex}}",
  tertiaire = "{{colors.tertiary.default.hex}}",
  conteneur = "{{colors.primary_container.default.hex}}",
  rouge     = "{{colors.rouge.default.hex}}",
  vert      = "{{colors.vert.default.hex}}",
  jaune     = "{{colors.jaune.default.hex}}",
  bleu      = "{{colors.bleu.default.hex}}",
  cyan      = "{{colors.cyan.default.hex}}",
}

vim.cmd("highlight clear")
vim.o.termguicolors = true
vim.g.colors_name = "pinksheep"
local function hi(g, o) vim.api.nvim_set_hl(0, g, o) end

hi("Normal",       { fg = c.texte, bg = c.fond })
hi("NormalFloat",  { fg = c.texte, bg = c.fond2 })
hi("FloatBorder",  { fg = c.primaire, bg = c.fond2 })
hi("CursorLine",   { bg = c.fond2 })
hi("CursorLineNr", { fg = c.primaire, bold = true })
hi("LineNr",       { fg = c.contour })
hi("Visual",       { bg = c.conteneur })
hi("Search",       { fg = c.fond, bg = c.tertiaire })
hi("IncSearch",    { fg = c.fond, bg = c.primaire })
hi("Pmenu",        { fg = c.texte, bg = c.fond3 })
hi("PmenuSel",     { fg = c.fond, bg = c.primaire })
hi("StatusLine",   { fg = c.texte, bg = c.fond3 })
hi("StatusLineNC", { fg = c.discret, bg = c.fond2 })
hi("WinSeparator", { fg = c.fond3 })
hi("VertSplit",    { fg = c.fond3 })
hi("MatchParen",   { fg = c.primaire, bold = true, underline = true })
hi("Comment",      { fg = c.contour, italic = true })
hi("Constant",     { fg = c.tertiaire })
hi("String",       { fg = c.vert })
hi("Character",    { fg = c.vert })
hi("Number",       { fg = c.jaune })
hi("Boolean",      { fg = c.jaune })
hi("Identifier",   { fg = c.texte })
hi("Function",     { fg = c.primaire })
hi("Statement",    { fg = c.second })
hi("Keyword",      { fg = c.second, italic = true })
hi("Operator",     { fg = c.discret })
hi("PreProc",      { fg = c.cyan })
hi("Type",         { fg = c.bleu })
hi("Special",      { fg = c.tertiaire })
hi("Title",        { fg = c.primaire, bold = true })
hi("Error",        { fg = c.rouge })
hi("ErrorMsg",     { fg = c.rouge })
hi("WarningMsg",   { fg = c.jaune })
hi("DiagnosticError", { fg = c.rouge })
hi("DiagnosticWarn",  { fg = c.jaune })
hi("DiagnosticInfo",  { fg = c.bleu })
hi("DiagnosticHint",  { fg = c.cyan })
hi("DiffAdd",      { fg = c.vert })
hi("DiffDelete",   { fg = c.rouge })
hi("DiffChange",   { fg = c.jaune })
hi("@variable",    { fg = c.texte })
hi("@property",    { fg = c.discret })
