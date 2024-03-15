local opt = vim.opt


-- Tab / Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.showtabline = 0
opt.expandtab = true  -- Convert tabs to spaces
opt.smartindent = true
opt.wrap = false    -- display lines as one long line

-- Search
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false				-- highlight all matches on previous search pattern


-- Appearance
opt.number = true					-- Set numbered lines
opt.relativenumber = true 			-- Set relative numbered lines
opt.termguicolors = true
opt.colorcolumn = '100'
opt.signcolumn = "yes"
opt.cmdheight = 1
opt.scrolloff = 10
opt.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal'
opt.sidescrolloff = 8
opt.completeopt = "menuone,noinsert,noselect"
opt.pumheight = 10  -- pop up menu height
opt.conceallevel = 0 -- so that `` is visible in markdown files
opt.wildmenu = true
opt.wildmenu = true -- wildmenu
opt.wildmode = 'longest:full,full' -- Command-line completion mode
opt.list = true
opt.listchars = { trail = '', tab = '', nbsp = '_', extends = '>', precedes = '<' } -- highlight



-- Behaviour
opt.clipboard:append('unnamedplus')	-- allows neovim to access the system clipboard
opt.mouse:append('a') 				-- allow the mouse to be used in neovim
opt.cursorline = true				-- highlight the current line
opt.encoding = 'UTF-8'
opt.fileencoding = 'UTF-8'
opt.hidden = true
opt.errorbells = true
opt.swapfile = false
opt.backup = false    -- creates a backup file
opt.writebackup = false    -- do not edit backups
opt.undodir = vim.fn.expand("~/.vim/undodir")
opt.undofile = true
opt.backspace = "indent,eol,start"
opt.splitright = true
opt.splitbelow = true
opt.autochdir = false
opt.iskeyword:append("-")
opt.modifiable = true
opt.guicursor = "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"
opt.laststatus = 3
opt.showmode = false
opt.showcmd = false
opt.updatetime = 50 -- faster completion (4000ms default)
opt.shell = bash
opt.confirm = true 					-- Confirm to save changes before exiting modified buffer
