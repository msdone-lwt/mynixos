-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize git-blame.nvim

-- @type LazySpec

return {
  "f-person/git-blame.nvim",
  event = "VeryLazy",
  opts = {
    enabled = true,
    message_template = " <summary> • <date> • ✨:<author> • <<sha>>",
    date_format = "%m-%d-%Y %H:%M:%S",
    virtual_text_column = 1,
    highlight_group = "gitBlameVirtualText", -- hl
    delay = 0, -- default: 250
  },
}
