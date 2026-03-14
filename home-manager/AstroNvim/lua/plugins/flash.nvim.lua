-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Flash

-- @type LazySpec

return {
  "folke/flash.nvim",
  event = "VeryLazy",
  specs = {
    {
      "folke/snacks.nvim",
      opts = {
        picker = {
          win = {
            input = {
              keys = {
                ["<c-s>"] = { "flash", mode = { "n", "i" } },
                ["s"] = { "flash" },
              },
            },
          },
          actions = {
            flash = function(picker)
              require("flash").jump({
                pattern = "^",
                label = { after = { 0, 0 } },
                search = {
                  mode = "search",
                  exclude = {
                    function(win)
                      return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                    end,
                  },
                },
                action = function(match)
                  local idx = picker.list:row2idx(match.pos[1])
                  picker.list:_move(idx, true, true)
                end,
              })
            end,
          },
        },
      },
    },
  },
  ---@type Flash.Config
  opts = {
    jump = {
      autojump = true,
    },
    label = {
      uppercase = true,
      before = true,
      after = false,
      rainbow = {
        enabled = true,
        -- number between 1 and 9
        shade = 9,
      },
    },
    modes = {
      char = {
        keys = { "f", "F", "t", "T" },
        jump_labels = true,
        jump = {
          autojump = true,
        },
      },
      treesitter = {
        jump = { pos = "range", autojump = true },
        label = { style = "overlay" },
      },
    },
  },
}
