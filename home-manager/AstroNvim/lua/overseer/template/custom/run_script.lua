return {
  name = "run_script",
  condition = {
    filetype = { "sh", "python", "typescript", "javascript", "lua", "c", "cpp", "rust" },
  },
  builder = function()
    local cmd
    local filetype = vim.bo.filetype
    local args
    local cwd = vim.fn.expand "%:p:h"

    if filetype == "sh" then
      cmd = "sh"
      args = { vim.fn.expand "%:p" }
    elseif filetype == "python" then
      cmd = "python3"
      args = { vim.fn.expand "%:p" }
    elseif filetype == "javascript" then
      -- cmd = "node"
      cmd = "tsx"
      args = { vim.fn.expand "%:p" }
    elseif filetype == "typescript" then
      cmd = "node"
      args = { "--experimental-strip-types", vim.fn.expand "%:p" }
    elseif filetype == "lua" then
      cmd = "lua"
      args = { vim.fn.expand "%:p" }
    elseif filetype == "c" then
      local sourceCodeFile = vim.fn.expand "%:p"
      local executableCodeFile = cwd .. "/" .. vim.fn.expand "%:t:r"
      cmd = "gcc"
      args = {
        "-fdiagnostics-color=always",
        "-g",
        sourceCodeFile,
        "-o",
        executableCodeFile,
        "-lstdc++",
        "-lm",
        "&&",
        executableCodeFile,
      }
    elseif filetype == "cpp" then
      local sourceCodeFile = vim.fn.expand "%:p"
      local executableCodeFile = cwd .. "/" .. vim.fn.expand "%:t:r"
      cmd = "g++"
      args = {
        "-fdiagnostics-color=always",
        "-g",
        sourceCodeFile,
        "-o",
        executableCodeFile,
        "-lstdc++",
        "-lm",
        "&&",
        executableCodeFile,
      }
    elseif filetype == "rust" then
      cmd = "cargo"
      args = {
        "run",
        "--example",
        vim.fn.expand "%:t:r",
      }
    else
      error("Unsupported filetype: " .. filetype)
    end

    return {
      name = vim.fn.expand "%:t",
      cmd = cmd,
      cwd = cwd,
      args = args,
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
