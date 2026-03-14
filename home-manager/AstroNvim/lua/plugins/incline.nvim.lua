-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize incline.nvim

-- @type LazySpec

return {
  {
    "b0o/incline.nvim",
    config = function()
      require("incline").setup {
        render = function(props)
          local devicons = require "nvim-web-devicons"
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then filename = "[No Name]" end
          local ft_icon, ft_color = devicons.get_icon_color(filename)

          local function get_git_diff()
            -- local icons = { removed = " ", changed = " ", added = " " }
            local icons = { removed = " ", changed = " ", added = " " }
            local signs = vim.b[props.buf].gitsigns_status_dict
            local labels = {}
            if signs == nil then return labels end
            for name, icon in pairs(icons) do
              if tonumber(signs[name]) and signs[name] > 0 then
                table.insert(labels, { icon .. signs[name] .. " ", group = "Diff" .. name })
              end
            end
            if #labels > 0 then table.insert(labels, { "┊ " }) end
            return labels
          end

          local function get_diagnostic_label()
            -- local icons = { error = "", warn = "", info = "", hint = "" }
            local icons = { error = " ", warn = " ", info = " ", hint = "󰌵 " }
            local label = {}

            for severity, icon in pairs(icons) do
              local n = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity[string.upper(severity)] })
              if n > 0 then table.insert(label, { icon .. n .. " ", group = "DiagnosticSign" .. severity }) end
            end
            if #label > 0 then table.insert(label, { "┊ " }) end
            return label
          end
          -- FIXME: Use lualine instead of heirline.
          -- local helpers = require "incline.helpers"
          -- local aerial_component = require "lualine.components.aerial" {
          --   self = { section = "x" },
          --   icons_enabled = true,
          --   sep = "  ",
          -- }
          -- local aerial_statusline = vim.api.nvim_win_call(
          --   props.win,
          --   function() return aerial_component:get_status { winid = props.win } end
          -- )
          return {
            { get_diagnostic_label() },
            { get_git_diff() },
            { (ft_icon or "") .. " ", guifg = ft_color, guibg = "none" },
            {
              filename .. " ",
              gui = vim.bo[props.buf].modified and "bold,italic" or "bold,italic",
              guifg = props.win == vim.api.nvim_get_current_win() and "#0fb81e" or "none",
            },
            -- { "┊  " .. vim.api.nvim_win_get_number(props.win), group = "DevIconWindows" },
            -- { helpers.eval_statusline(aerial_component:get_status(), { winid = props.win }) }, --  FIXME: Use lualine instead of heirline.
          }
        end,
        window = {
          margin = {
            horizontal = 0,
            vertical = 0,
          },
          overlap = {
            borders = true,
            statusline = false,
            tabline = false,
            winbar = false,
          },
          placement = {
            horizontal = "right",
            vertical = "top",
          },
        },
        ignore = {
          buftypes = "special",
          filetypes = { "Avante" },
          floating_wins = true,
          unlisted_buffers = true,
          wintypes = "special",
        },
        hide = {
          cursorline = "focused_win", -- `bool` | `"focused_win"` :如果为 `true`，与光标在同一行的 Incline 状态栏将被隐藏。如果为 `"focused_win"`，如果光标在同一行，则焦点窗口的 Incline 状态栏将被隐藏。
          focused_win = false,
          only_win = false,
        },
      }
    end,
    -- Optional: Lazy load Incline
    event = "VeryLazy",
  },
}
