return {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 999,
    config = function()
        vim.cmd("colorscheme onedark")

        -- Main options --
        vim.g.onedark_style = 'deep' -- Default theme style. Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
        vim.g.onedark_transparent = true -- Show/hide background
        vim.g.onedark_term_colors = false -- Change terminal color as per the selected theme style
        vim.g.onedark_ending_tildes = false -- Show the end-of-buffer tildes. By default they are hidden
        vim.g.onedark_cmp_itemkind_reverse = false -- Reverse item kind highlights in cmp menu

        -- Change code style options --
        vim.g.onedark_code_style = {
            comments = 'italic',
            keywords = 'none',
            functions = 'none',
            strings = 'none',
            variables = 'none',
        }
    end,
}

