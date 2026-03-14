-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize autosave.nvim

-- @type LazySpec

return {
  "0x00-ketsu/autosave.nvim",
  -- lazy-loading on events
  event = { "InsertLeave", "TextChanged" },
  config = function()
    require("autosave").setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      prompt_style = nil
    }
  end,
}
