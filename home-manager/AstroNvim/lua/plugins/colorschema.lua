return {
  { "craftzdog/solarized-osaka.nvim", lazy = true, opts = {
    transparent = true,
  } },
  { "sainnhe/everforest", lazy = true },
  { "Mofiqul/dracula.nvim", lazy = true },
  { "folke/tokyonight.nvim", lazy = true },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    commit = "fa42eb5e26819ef58884257d5ae95dd0552b9a66",
    priority = 1000,
    config = function()
      require("catppuccin").setup {
        transparent_background = true, -- disables setting the background color.
        auto_integrations = true,
      }
    end,
  },
}
