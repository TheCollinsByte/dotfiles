local keymap = vim.keymap

local opts = { noremap = true, silent = true }

-- Space as leader
keymap.set('n', '<Space>', '', opts)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
