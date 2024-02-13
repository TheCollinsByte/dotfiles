-- Reload neovim config
vim.api.nvim_create_user_command('', function()
		for name, _ in pairs(package.loaded) do
				if name:match('^plugins') then
						package.loaded[name] = nil
				end
		end

		dotfile(vim.env.MYVIMRC)
		vim.notify('Nvim Configuration reloaded!', vim.log.level.INFO)
end, {})
