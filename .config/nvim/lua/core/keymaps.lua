local keymap = vim.keymap

-- TODO: Helper Function use to set keymap

local opts = { noremap = true, silent = true }


-- Modes
-- normal_mode = 'n', insert_mode = 'i', visual_mode = 'v',
-- visual_block_mode = 'x', term_mode = 't', command_mode = 'c',

-- Space as leader
keymap.set('n', '<Space>', '', opts)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '


-- Split/Pane and Window Navigation



-- Window Management



-- Indenting
keymap.set('v', '<', '<gv')
keymap.set('v', '>', '>gv')


-- Comments

