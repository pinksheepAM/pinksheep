-- Neovim PinkSheep : réglages simples + couleurs du fond d'écran
vim.g.mapleader = " "
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = "a"
vim.o.clipboard = "unnamedplus"   -- copier/coller avec le reste du système
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.cursorline = true
vim.o.scrolloff = 6
vim.o.signcolumn = "yes"
vim.o.undofile = true
vim.o.termguicolors = true

-- Couleurs générées par matugen (lua/couleurs.lua)
pcall(require, "couleurs")

-- Raccourcis pratiques
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Enregistrer" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>",  { desc = "Quitter" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")
