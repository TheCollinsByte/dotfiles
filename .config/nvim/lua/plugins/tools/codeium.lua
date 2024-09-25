local status_ok, codeium = pcall(require, 'codeium')
if not status_ok then
    return
end

codeium.setup({
    max_history_length = 1000,
    completion = {
        complete_functions = true,
        engine = 'nvim-cmp',
    },
    filetypes = {
        yaml = true,
        markdown = false,
        help = true,
        gitcommit = true,
        gitrebase = true,
        hgcommit = true,
        svn = true,
        cvs = true,
        ["."] = true
    }
});
