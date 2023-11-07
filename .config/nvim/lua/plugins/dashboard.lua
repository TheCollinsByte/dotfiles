return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	config = function()
		require("dashboard").setup({
			theme = "hyper",
			vim.cmd("highlight DashboardCenter guifg=#9fb2ca"),
			preview_file_height = 12,
			preview_file_width = 80,
			config = {
				week_header = {
					enable = true,
				},
				footer = {
					"Doing the same thing over and over again, but expecting different results is the definition of Insanity",
				},
				shortcut = {
					{ desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
					{
						icon = " ",
						icon_hl = "@variable",
						desc = "Files",
						group = "Label",
						action = "Telescope find_files",
						key = "f",
					},
					{
						desc = " Apps",
						group = "DiagnosticHint",
						action = "<Cmd>Telescope app<CR>",
						key = "a",
					},
					{
						desc = " dotfiles",
						group = "Number",
						action = "Telescope dotfiles",
						key = "d",
					},
				},
			},
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
