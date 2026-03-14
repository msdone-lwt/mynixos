if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize SmoothCursor.nvim

-- @type LazySpec

return {
  "gen740/SmoothCursor.nvim",
  config = function()
    require("smoothcursor").setup {
      -- NOTE: common
      autostart = true, -- Automatically start SmoothCursor
      always_redraw = true, -- Redraw the screen on each update
      flyin_effect = "top", -- Choose "bottom" or "top" for flying effect
      speed = 25, -- Max speed is 100 to stick with your current position
      intervals = 35, -- Update intervals in milliseconds
      priority = 100, -- Set marker priority
      timeout = 3000, -- Timeout for animations in milliseconds
      threshold = 3, -- Animate only if cursor moves more than this many lines
      max_threshold = nil, -- If you move more than this many lines, don't animate (if `nil`, deactivate check)
      disable_float_win = false, -- Disable in floating windows
      enabled_filetypes = nil, -- Enable only for specific file types, e.g., { "lua", "vim" }
      disabled_filetypes = { "alpha" }, -- Disable for these file types, ignored if enabled_filetypes is set. e.g., { "TelescopePrompt", "NvimTree" }
      -- Show the position of the latest input mode positions.
      -- A value of "enter" means the position will be updated when entering the mode.
      -- A value of "leave" means the position will be updated when leaving the mode.
      -- `nil` = disabled
      show_last_positions = "enter",
      -- 经典透明背景
      -- vim.api.nvim_set_hl(0, "SmoothCursorLinehl", { ctermbg = 236, bg = "#3e4451" }),
      -- 柔和的灰色背景
      -- vim.api.nvim_set_hl(0, 'SmoothCursorLinehl', { ctermbg = 238, bg = '#2c313a' }),
      -- 浅蓝色背景
      -- vim.api.nvim_set_hl(0, 'SmoothCursorLinehl', { ctermbg = 24, bg = '#2e3440' }),
      -- 浅绿色背景
      -- vim.api.nvim_set_hl(0, 'SmoothCursorLinehl', { ctermbg = 22, bg = '#3b4252' }),
      -- 透明背景 + 下划线
      -- vim.api.nvim_set_hl(0, "SmoothCursorLinehl", { underline = true }),
      -- 深色背景
      -- vim.api.nvim_set_hl(0, 'SmoothCursorLinehl', { ctermbg = 235, bg = '#1c1f24' }),
      -- 明亮的背景
      -- vim.api.nvim_set_hl(0, 'SmoothCursorLinehl', { ctermbg = 249, bg = '#4c566a' }),

      -- NOTE: default mode
      type = "default",
      cursor = "",
      texthl = "SmoothCursorRed",
      linehl = "SmoothCursorRed",
      -- fancy mode
      fancy = {
        enable = true, -- enable fancy mode
        -- head = { cursor = "▷", texthl = "SmoothCursor", linehl = "SmoothCursorLinehl" }, -- false to disable fancy head
        head = { cursor = "▷", texthl = "SmoothCursor", linehl = nil }, -- false to disable fancy head
        -- head = { cursor = "▷", texthl = "SmoothCursor", linehl = "CursorLine" }, -- false to disable fancy head
        -- NOTE:
        -- CursorLine: nvim 默认的光标所在行的 hl, 和 nil 的区别是切换窗口时 (c-h\j\k\l) 会有渐变动画，会把 NOTE、 FIXME 的高亮取消掉 ( 光标在 NOTE、 FIXME 上 )
        -- nil: 使用 nvim 默认的 CursorLine，区别是切换窗口时 (c-h\j\k\l)* 没 * 有渐变动画
        -- SmoothCursorLinehl: 自定义 hl，参上
        body = {
          { cursor = "󰝥", texthl = "SmoothCursorRed" },
          { cursor = "󰝥", texthl = "SmoothCursorOrange" },
          { cursor = "●", texthl = "SmoothCursorYellow" },
          { cursor = "●", texthl = "SmoothCursorGreen" },
          { cursor = "•", texthl = "SmoothCursorAqua" },
          { cursor = ".", texthl = "SmoothCursorBlue" },
          { cursor = ".", texthl = "SmoothCursorPurple" },
        },
        tail = { cursor = nil, texthl = "SmoothCursor" }, -- false to disable fancy tail
      },
      -- NOTE: matrix mode
      matrix = { -- NOTE: Loaded when 'type' is set to "matrix"
        head = {
          -- Picks a random character from this list for the cursor text
          cursor = require "smoothcursor.matrix_chars",
          -- Picks a random highlight from this list for the cursor text
          texthl = {
            "SmoothCursor",
          },
          linehl = "CursorLine", -- No line highlight for the head
        },
        body = {
          length = 6, -- Specifies the length of the cursor body
          -- Picks a random character from this list for the cursor body text
          cursor = require "smoothcursor.matrix_chars",
          -- Picks a random highlight from this list for each segment of the cursor body
          texthl = {
            "SmoothCursorGreen",
            "SmoothCursorRed",
            "SmoothCursorOrange",
            "SmoothCursorYellow",
            "SmoothCursorAqua",
            "SmoothCursorBlue",
            "SmoothCursorPurple",
          },
        },
        tail = {
          -- Picks a random character from this list for the cursor tail (if any)
          cursor = nil,
          -- Picks a random highlight from this list for the cursor tail
          texthl = {
            "SmoothCursor",
          },
        },
        unstop = false, -- Determines if the cursor should stop or not (false means it will stop)
      },
    }
  end,
}
