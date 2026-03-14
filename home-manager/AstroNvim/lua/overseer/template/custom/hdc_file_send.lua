return {
  name = "'hdc file send' current file",
  params = {
    target = { optional = false, type = "string", desc = "target folder" },
  },
  builder = function(params)
    -- 获取当前文件的完整路径，并将路径中的'/'替换为'\\'
    local current_file_path = vim.fn.expand "%:p"
    current_file_path = current_file_path:gsub("/", "\\")

    -- 构建命令
    local cmd = "hdc.exe file send '\\\\wsl$\\Ubuntu-20.04" .. current_file_path .. "' " .. params.target
    return {
      name = "hdc file send " .. vim.fn.expand "%:t",
      cmd = cmd,
      cwd = vim.fn.expand "%:p:h",
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
