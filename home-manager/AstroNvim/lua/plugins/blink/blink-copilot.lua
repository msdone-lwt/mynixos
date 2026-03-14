-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize blink-copilot

-- @type LazySpec

return {
  "fang2hou/blink-copilot",
  lazy = true,
  opts = {
    max_completions = 3,
    max_attempts = 4,
    kind_name = "Copilot", ---@type string | false
    kind_icon = " ", ---@type string | false
    kind_hl = false, ---@type string | false
    debounce = 200, ---@type integer | false
    auto_refresh = {
      backward = true,
      forward = true,
    },
  },
  specs = {
    {
      "Saghen/blink.cmp",
      optional = true,
      opts = {
        sources = {
          default = { "copilot" },
          providers = {
            copilot = {
              name = "copilot",
              module = "blink-copilot",
              score_offset = 100,
              async = true,
              opts = {
                -- Local options override global ones
                max_completions = 3, -- Override global max_completions

                -- Final settings:
                -- * max_completions = 3
                -- * max_attempts = 2
                -- * all other options are default
              },
            },
          },
        },
        -- keymap = {
        --   preset = "super-tab",
        --   ["<Tab>"] = {
        --     function(cmp)
        --       if vim.b[vim.api.nvim_get_current_buf()].nes_state then
        --         cmp.hide()
        --         return (
        --           require("copilot-lsp.nes").apply_pending_nes()
        --           and require("copilot-lsp.nes").walk_cursor_end_edit()
        --         )
        --       else
        --         return cmp.select_next()
        --       end
        --     end,
        --     "snippet_forward",
        --     "fallback",
        --   },
        -- },
      },
    },
  },
}
