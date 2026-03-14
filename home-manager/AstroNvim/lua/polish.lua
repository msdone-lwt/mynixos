-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- This will run **last** in the setup process and is a good place to configure
-- things like custom filetypes. This just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- NOTE: 20240902 activate this file
-- font: Monaco Nerd Font

-- vim.cmd [[ highlight Cursor guifg=red guibg=yellow blend=100 ]]
vim.g.have_nerd_font = true
-- NOTE: copilot
vim.g.copilot_workspace_folders = vim.fn.expand "%:p:h"

-- NOTE: git-blame.nvim
-- vim.api.nvim_set_hl(
--   0,
--   "gitBlameVirtualText",
--   { fg = "#696c76", ctermfg = "#696c76", bg = "#1e222a", ctermbg = "#1e222a", italic = true, cterm = { italic = true } }
-- )
vim.api.nvim_set_hl(0, "gitBlameVirtualText", { fg = "#696c76", bg = "#1e222a", italic = true })

-- NOTE: SmoothCursor.nvim
-- vim.api.nvim_create_augroup("SmoothCursorConfig", { clear = true })

-- vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
--   callback = function()
--     vim.api.nvim_set_hl(0, "SmoothCursor", { fg = "#baf16a" })
--     vim.fn.sign_define("smoothcursor", { text = "X" })
--     vim.cmd "redraw"
--   end,
-- })

-- vim.api.nvim_create_autocmd("ModeChanged", {
--   group = "SmoothCursorConfig",
--   callback = function()
--     local current_mode = vim.fn.mode()
--     local cursor_configs = {
--       n = { fg = "#50A4E9", text = "💥" },
--       v = { fg = "#bf616a", text = "" },
--       V = { fg = "#bf616a", text = "" },
--       i = { fg = "#668aab", text = "" },
--       c = { fg = "#baf16a", text = "󰘳" },
--     }
--
--     local config = cursor_configs[current_mode] or {}
--     if config.fg then vim.api.nvim_set_hl(0, "SmoothCursor", { fg = config.fg }) end
--     if config.text then vim.fn.sign_define("smoothcursor", { text = config.text }) end
--
--     if current_mode == "c" then vim.cmd "redraw" end
--   end,
-- })

-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3
vim.g.augment_disable_tab_mapping = true
-- OSC 52
-- vim.g.clipboard = "osc52"
