-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize overseer

-- @type LazySpec

return {
  "stevearc/overseer.nvim",
  config = function()
    local overseer = require "overseer"
    overseer.setup {
      dap = false,
      templates = {
        "builtin",
        "make",
        "cargo",
        "shell",
        "custom.run_script",
        "custom.hdc_file_send",
        "custom.hdc_file_send_folder",
      },
      task_list = {
        direction = "bottom",
        bindings = {
          ["<C-u>"] = false,
          ["<C-d>"] = false,
          ["<C-h>"] = false,
          ["<C-j>"] = false,
          ["<C-k>"] = false,
          ["<C-l>"] = false,
        },
      },
    }
    -- custom behavior of make templates
    overseer.add_template_hook({
      module = "^make$",
    }, function(task_defn, util)
      util.add_component(task_defn, { "on_output_quickfix", open_on_exit = "failure" })
      util.add_component(task_defn, "on_complete_notify")
      util.add_component(task_defn, { "display_duration", detail_level = 1 })
    end)
  end,
}
