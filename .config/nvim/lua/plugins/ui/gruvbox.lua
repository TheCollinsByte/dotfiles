local status_ok, gruvbox = pcall(require, 'gruvbox')
if not status_ok then
	return
end

gruvbox.setup({
	terminal_color = true,
	undercurl = true,
	underline = true,
	bold = true,
	italic = {
		strings = true,
		emphasis = true,
		comments = true,
		operators = false,
		folds = true,
	},
	strikethrough = true,
  	invert_selection = false,
	invert_signs = false,
	invert_tabline = false,
	invert_intend_guides = false,
	inverse = true, -- invert background for search, diffs, statuslines and errors
	contrast = "", -- can be "hard", "soft" or empty string
	palette_overrides = {
		bright_green = '#990000',
	},
	overrides = {
		SignColumn = {bg = "#ff9900"},
		["@lsp.type.method"] = { bg = "#ff9900" },
		["@comment.lua"] = { bg = "#000000" },
	},
	dim_inactive = false,
	transparent_mode = false,
})

gruvbox.load()

-- transparent background
-- vim.api.nvim_set_hl(0, "Normal", {bg = "none"})
-- vim.api.nvim_set_hl(0, "NormalFloat", {bg = "none"})
-- vim.api.nvim_set_hl(0, "FloatBorder", {bg = "none"})
-- vim.api.nvim_set_hl(0, "Pmenu", {bg = "none"})
