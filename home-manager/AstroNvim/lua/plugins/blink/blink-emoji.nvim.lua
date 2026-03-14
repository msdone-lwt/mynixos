-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize blink-emoji.nvim

-- @type LazySpec

return {
  "moyiz/blink-emoji.nvim",
  lazy = true,
  specs = {
    {
      "Saghen/blink.cmp",
      optional = true,
      opts = {
        sources = {
          -- enable the provider by default (automatically extends when merging tables)
          default = { "emoji" },
          providers = {
            -- Specific details depend on the blink source
            emoji = {
              name = "Emoji",
              module = "blink-emoji",
              min_keyword_length = 1,
              -- score_offset = -1,
              score_offset = 15, -- Tune by preference
              opts = { insert = true }, -- Insert emoji (default) or complete its name
              should_show_items = true
            },
          },
        },
      },
    },
  },
}
