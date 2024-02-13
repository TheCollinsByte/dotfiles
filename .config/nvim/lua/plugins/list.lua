local function load_config(package)
    return function() require('plugins.' .. package) end
end

return {
	-- UI
	{
		'ellisonleao/gruvbox.nvim',
		config = load_config('ui.gruvbox'),
		lazy = false,
		priority = 1000,
	},

	{
		'nvimdev/dashboard-nvim',
		config = load_config('ui.dashboard'),
		-- Only load when no arguments
		event = function()
		    if vim.fn.argc() == 0 then
			return 'VimEnter'
		    end
		end,
		cmd = 'Dashboard',
		},

	{
		'rcarriga/nvim-notify',
		config = load_config('ui.notify'),
		event = 'VeryLazy',
		cmd = 'Notifications',
	},

	{
        	'nvim-lualine/lualine.nvim',
        	config = load_config('ui.lualine'),
        	event = { 'BufReadPre', 'BufNewFile' },
    	},

	{
		'folke/noice.nvim',
		config = load_config('ui.noice'),
		event = 'VeryLazy',
		dependencies = {
			'MunifTanjim/nui.nvim',
			'rcarriga/nvim-notify'
		},
	},
	
	-- Language
	

	-- Treesitter
	

	-- LSP
	{
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v3.x',
		dependencies = {
		    'neovim/nvim-lspconfig',
		    'williamboman/mason-lspconfig.nvim',
		},
		config = load_config('lang.lsp-zero'),
		event = { 'BufReadPre', 'BufNewFile' },
	},

	{
		'neovim/nvim-lspconfig',
		dependencies = {
				'williamboman/mason.nvim',
				'williamboman/mason-lspconfig.nvim',
		},
		config = load_config('lang.mason'),
		cmd = 'Mason',
	},

	-- Completion
    {
		'hrsh7th/nvim-cmp',
		dependencies = {
            'hrsh7th/cmp-nvim-lsp',
		    'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',

            'saadparwaiz1/cmp_luasnip',
            -- 'hrsh7th/cmp-nvim-lsp-signature-help',
            -- 'hrsh7th/cmp-nvim-lua',
		},
		config = load_config('lang.cmp'),
		event = 'InsertEnter',
    },


	{
			'L3MON4D3/LuaSnip',
			version = "v2.*",
			dependencies = { 'rafamadriz/friendly-snippets' },
			build = "make install_jsregexp",
			event = "InsertEnter"
	},


	-- Tools
	 

	-- Telescope
	{
		'nvim-telescope/telescope.nvim',
		branch = '0.1.x',
		dependencies = {
		    'nvim-lua/plenary.nvim',
		    {
			'nvim-telescope/telescope-fzf-native.nvim',
			build = 'make',
		    },
		    'nvim-telescope/telescope-symbols.nvim',
		    'molecule-man/telescope-menufacture',
		    'debugloop/telescope-undo.nvim',
		    'ThePrimeagen/harpoon',
		},
		config = load_config('tools.telescope'),
		cmd = 'Telescope',
	}

	-- Git
}
