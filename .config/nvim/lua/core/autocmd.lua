---- auto-format on Save
local lsp_fmt_group = vim.api.nvim_create_augroup("LspFormattingGroup", {})
vim.api.nvim_create_autocmd("BufWritePost", {
	group = lsp_fmt_group,
	callback = function()
		local efm = vim.lsp.get_active_clients({ name = "efm" })

		if vim.tbl_isempty(efm) then
			return
		end

		vim.lsp.buf.format({ name = "efm", async = true })
	end,
})


--[[ TextYankPost
autocmd({"BufWritePre"}, {

})
]]--


--[[ Clean white space at the end
autocmd({"BufWritePre"}, {

})
]]--
