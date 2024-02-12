local opt = vim.opt


-- Tab / Indentation
opt.tabstop = 4
opt.smartindent = true
opt.wrap = false					-- Display lines as one long line 


-- Search
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false				-- highlight all matches on previous search pattern


-- Appearance
opt.number = true					-- Set numbered lines
opt.relativenumber = true 			-- Set relative numbered lines
opt.termguicolors = true
opt.scrolloff = 10


-- Behaviour
opt.clipboard:append('unnamedplus')	-- allows neovim to access the system clipboard
opt.mouse:append('a') 				-- allow the mouse to be used in neovim
opt.cursorline = true				-- highlight the current line
opt.encoding = 'UTF-8'
opt.fileencoding = 'UTF-8'
opt.confirm = true 					-- Confirm to save changes before exiting modified buffer
