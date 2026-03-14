-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize git-dashboard-nvim

-- @type LazySpec

return {
  {
    "juansalvatore/git-dashboard-nvim",
    event = "VeryLazy",
    config = function()
      require("git-dashboard-nvim").setup {
        -- filled_squares = { "", "", "", "", "", "" },
        empty_square = "0",
        filled_squares = { "1", "2", "3", "4", "5", "6" },
      }
    end,
  },
}
