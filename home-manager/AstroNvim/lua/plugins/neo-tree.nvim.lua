-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize neo-tree.nvim

-- @type LazySpec

local Snacks = require "snacks"
local function on_move(data) Snacks.rename.on_rename_file(data.source, data.destination) end
local events = require "neo-tree.events"
-- local function on_move(data) require("astrolsp.file_operations").didRenameFiles { from = data.source, to = data.destination } end

    -- {
    --   "nvim-neo-tree/neo-tree.nvim",
    --   opts = function(_, opts)
    --     -- local Snacks = require("snacks")
    --     local function on_move(data)
    --       Snacks.rename.on_rename_file(data.source, data.destination)
    --     end
    --     local events = require "neo-tree.events"
    --     opts.event_handlers = opts.event_handlers or {}
    --     vim.list_extend(opts.event_handlers, {
    --       { event = events.FILE_MOVED, handler = on_move },
    --       { event = events.FILE_RENAMED, handler = on_move },
    --     })
    --   end,
    -- },
    -- {
    --   "nvim-neo-tree/neo-tree.nvim",
    --   opts = {
    --     -- local function on_move(data)
    --     --   Snacks.rename.on_rename_file(data.source, data.destination)
    --     -- end
    --     event_handlers = {
    --       { event = require("neo-tree.events").FILE_MOVED, handler = function(data)
    --         Snacks.rename.on_rename_file(data.source, data.destination)
    --       end },
    --       { event = require("neo-tree.events").FILE_RENAMED, handler = function(data)
    --         Snacks.rename.on_rename_file(data.source, data.destination)
    --       end },
    --     }
    --   }
    -- }


return {
  "nvim-neo-tree/neo-tree.nvim",
  event = "VeryLazy",  -- lazy event
  opts = {
    -- neo-tree 重命名和 LSP 联动
    -- event_handlers = {
      -- {
      --   event = events.FILE_MOVED,
      --   handler = on_move,
      -- },
      -- {
      --   event = events.FILE_RENAMED,
      --   handler = on_move,
      -- },
    -- },
    -- neo-tree 添加 file 到 avante ask 可选项
    filesystem = {
      commands = {
        avante_add_files = function(state)
          local node = state.tree:get_node()
          local filepath = node:get_id()
          local relative_path = require("avante.utils").relative_path(filepath)

          local sidebar = require("avante").get()

          local open = sidebar:is_open()
          -- ensure avante sidebar is open
          if not open then
            require("avante.api").ask()
            sidebar = require("avante").get()
          end

          sidebar.file_selector:add_selected_file(relative_path)

          -- remove neo tree buffer
          if not open then sidebar.file_selector:remove_selected_file "neo-tree filesystem [1]" end
        end,
      },
    },
    window = {
      mappings = {
        ["oa"] = "avante_add_files",
      },
    },
  },
}
