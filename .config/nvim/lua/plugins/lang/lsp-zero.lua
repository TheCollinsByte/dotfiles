local status_ok, lsp_zero = pcall(require, 'lsp-zero')
if not status_ok then
	return
end

lsp_zero.on_attach(function(client, bufnr)
	lsp_zero.default_keymaps({ buffer = bufnr })
end)


require('mason').setup({})
require('mason-lspconfig').setup({})
