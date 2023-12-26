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

        -- Lualine options --
        vim.g.onedark_lualine = {
            transparent = true, -- Lualine center bar transparency
        }

        -- Plugins Config --
        vim.g.onedark_diagnostics = {
            darker = false, -- Darker colors for diagnostic
            undercurl = true, -- Use undercurl instead of underline for diagnostics
            background = false, -- Use background color for virtual text
        }

        -- Custom Highlights --
        vim.g.onedark_colors = {
            -- bright_orange = "#ff8800",
            -- green = '#00ffaa',
        }
        vim.g.onedark_highlights = {
            -- ["@keyword"] = { fg = '$green' },
            -- ["@string"] = { fg = '$bright_orange', bg = '#00ff00', fmt = 'bold' },
            -- ["@function"] = { fg = '#0000ff', sp = '$cyan', fmt = 'underline,italic' },
            -- ["@function.builtin"] = { fg = '#0059ff' }
        }

        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
        vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
    end,
}

