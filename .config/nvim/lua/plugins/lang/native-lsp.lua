require'lspconfig'.gopls.setup{
		cmd = {'/home/collo/.go/bin/gopls'},
		on_attach = function() 		-- This function runs on every buffer when it first gets attached to the LSP
				capabilities = capabilities
				vim.keymap.set("n", "K", vim.lsp.buf.hover, {buffer = 0}) 			-- 0 means whenver the current buffer is
				vim.keymap.set("n", "gd", vim.lsp.buf.definition, {buffer = 0})
				vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, {buffer = 0})
				vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {buffer = 0})
				-- vim.keymap.set("n", "gr", vim.lsp.buf.reference, {buffer = 0})			-- goto reference
				vim.keymap.set("n", "<leader>df", vim.diagnostic.goto_next, {buffer = 0})
				vim.keymap.set("n", "<leader>db", vim.diagnostic.goto_prev, {buffer = 0})
				vim.keymap.set("n", "<leader>dl", "<cmd>Telescope diagnostics<cr>", {buffer = 0})
				vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, {buffer = 0}) 		-- run :wa for Write All because it changed it in another buffer
				vim.keymap.set("n", "<leader>i", vim.lsp.buf.code_action, {buffer = 0}) 		-- run :wa for Write All because it changed it in another buffer
				-- Telescope lsp_references
		end,
}		-- connect to server
