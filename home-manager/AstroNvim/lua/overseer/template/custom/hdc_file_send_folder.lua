return {
  name = "'hdc file send' current folder",
  params = {
    target = { optional = false, type = "string", desc = "target folder" },
  },
  builder = function(params)
    local cwd = vim.fn.expand "%:p:h"
    -- 获取当前目录的完整路径，并将路径中的'/'替换为'\\'
    local current_folder_path = cwd:gsub("/", "\\")

    -- 构建命令
    local cmd = "hdc.exe file send '\\\\wsl$\\Ubuntu-20.04" .. current_folder_path .. "' " .. params.target
    return {
      name = "hdc file send " .. vim.fn.expand "%:p:h:t",
      cmd = cmd,
      cwd = cwd,
      -- args = { params.target },
      components = {
        "task_list_on_start",
        "display_duration",
        "on_exit_set_status",
        "on_complete_notify",
        "on_output_summarize",
      },
    }
  end,
}
