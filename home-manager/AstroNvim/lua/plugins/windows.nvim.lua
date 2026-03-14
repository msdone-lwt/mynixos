-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize windows.nvim

-- @type LazySpec

return {
  "anuvyklack/windows.nvim",
  dependencies = {
    "anuvyklack/middleclass",
    "anuvyklack/animation.nvim",
  },
  config = function()
    vim.o.winwidth = 15
    vim.o.winminwidth = 15
    vim.o.equalalways = false
    require("windows").setup {
      autowidth = {
        enable = true,
      },
      ignore = { --			  |windows.ignore|
        buftype = { "quickfix" },
        filetype = { "NvimTree", "neo-tree", "undotree", "gundo", "Avante", "AvanteInput", "AvanteSelectedFiles" },
      },
      animation = {
        enable = true,
        duration = 300,
        fps = 30,
        -- NOTE: docs: https://github.com/anuvyklack/animation.nvim/blob/main/lua/animation/easing.lua
        -- line、in_out_sine、out_sine、out_quad、in_out_quad
        easing = "in_out_quad",
      },
    }
  end,
}
