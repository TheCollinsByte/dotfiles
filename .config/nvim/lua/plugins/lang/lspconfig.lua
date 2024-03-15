-- Import lspconfig plugin
local lspconfig = require('lspconfig')

-- Import cmp-nvim-lsp plugin
local cmp_nvim_lsp = require('cmp_nvim_lsp')
local capabilities = cmp_nvim_lsp.default_capabilities()

local keymap = vim.keymap	-- for conciseness

local icons = require('lib.icons').diagnostics

local opts = { noremap = true, silent = true }
local on_attach = function(client, bufnr)
		opts.buffer = bufnr

		-- set keybinds
		opts.desc = "Show LSP references"
		keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)	-- Show definition, references

		opts.desc = "Go to declaration"
		keymap.set("n", "gD", "vim.lsp.buf.declaration", opts)	-- go to declaration

		opts.desc = "Show LSP definitions"
		keymap.set("n", "gd", "<cmdD>Telescope lsp_definitions<CR>", opts)	-- show lsp definitions

		opts.desc = "Show LSP implementations"
		keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)	-- Show lsp implementation

		opts.desc = "Show LSP type definitions"
		keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)	-- Show lsp type definitions

		opts.desc = "See available code actions"
		keymap.set({"n", "v"}, "<leader>ca", keymap.lsp.buf.code_action, opts)	-- see available code actions, in visual mode will apply

		opts.desc = "Smart rename"
		keymap.set("n", "<leader>rn", keymap.lsp.buf.rename, opts)	-- smart rename

		opts.desc = "Show buffer diagnostics"
		keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)	-- Show diagnostics for file

		opts.desc = "Show line diagnostics"
		keymap.set("n", "<leader>d", keymap.diagnostic.open_float, opts)	-- Show diagnostics for line

		opts.desc = "Go to previous diagnostic"
		keymap.set("n", "[d", keymap.diagnostic.goto_prev, opts)	-- jump to previous diagnostic in buffer

		opts.desc = "Go to next diagnostic"
		keymap.set("n", "]d", keymap.diagnostic.goto_next, opts)	-- jump to next diagnostic in buffer

		opts.desc = "Show documentation for what is under cursor"
		keymap.set("n", "K", keymap.lsp.buf.hover, opts)	-- show ducumentation for what is under cursor

		opts.desc = "Restart LSP"
		keymap.set("n", "<leader>rs", "<cmd>LspRestart<CR>", opts)	-- mapping to restart lsp if necessary
end


-- Change the Diagnostic symbols in the sign column (gutter)
local signs = { Error = icons.Error, Warn = icons.Warning, Hint = icons.Hint, Info = icons.Information }
for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
end


-- configure gopls server
lspconfig["gopls"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure Rust server
lspconfig["rust_analyzer"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure Java server
lspconfig["jdtls"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure clangd server
lspconfig["clangd"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure Python server
lspconfig["pyright"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure typescript server
lspconfig["tsserver"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure lua server
lspconfig["lua_ls"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure html server
lspconfig["html"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure css server
lspconfig["cssls"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure tailwindcss server
lspconfig["tailwindcss"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
})

-- configure emmet server
lspconfig["emmet_ls"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
		filetypes = {"html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less"},
})


--[[
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
--]]

require('mason-lspconfig').setup({
		-- List of servers for mason to install
		ensure_installed = {
				'gopls', 			-- GoLang Langugae Server
				'rust_analyzer', 	-- Rust Langugae Server
				'jdtls', 			-- Java Langugae Server
				'tsserver', 		-- Typescript Langugae Server
				'dartls', 			-- Dart Langugae Server
				'lua_ls',			-- Lua Language Server
				'pyright',			-- Python Language Server
				'clangd',			-- C/C++ Language Server
				'sqls',				-- SQL Language Server
				'gleam',			-- gleam Language Server

				-- Web Development
				'html',				-- HTML Language Server
				'cssls',			-- CSS Language Server
				'tailwindcss',			-- Taiwind Language Server
				'graphql',			-- Graphql Language Server
				'emmet_ls',			-- Emmet Language Server
		},

		-- auto-install configured server (with lspconfig)
		automatic_installation = true, 	-- not the same as ensure_installed
})
