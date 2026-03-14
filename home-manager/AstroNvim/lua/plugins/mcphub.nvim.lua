-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize mcphub.nvim
-- NOTE: 需要安装 npx(npm install -g npx) 和 uvx(curl -LsSf https://astral.sh/uv/install.sh | sh)

-- @type LazySpec

return {
  "ravitemer/mcphub.nvim",
  -- Ensure these are installed as they're required by most MCP servers
  -- node --version    # Should be >= 18.0.0
  -- python --version  # Should be installed
  -- uvx --version    # Should be installed
  -- npx --version    # Should be installed
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
  },
  cmd = "MCPHub", -- lazily start the hub when `MCPHub` is called
  build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
  config = function()
    -- 创建配置目录（如果不存在）
    local config_dir = vim.fn.stdpath "config" .. "/lua/mcphub"
    local config_path = config_dir .. "/mcpservers.json"

    -- 从环境变量读取 API 密钥，如果不存在则为空
    local amap_api_key = os.getenv "AMAP_MAPS_API_KEY" or ""
    local notion_api_key = os.getenv "NOTION_INTEGRATION_TOKEN" or ""
    if amap_api_key == "" then
      vim.notify("请设置 AMAP_MAPS_API_KEY 环境变量，否则 mcp:amap-maps 无法使用!", vim.log.levels.WARN)
    end
    if notion_api_key == "" then
      vim.notify("请设置 NOTION_INTEGRATION_TOKEN 环境变量，否则 mcp:notion-mcp-server 无法使用!", vim.log.levels.WARN)
    end

    require("mcphub").setup {
      -- Required options
      port = 3000, -- Port for MCP Hub server
      config = config_path, -- Config file in neovim config directory

      -- Optional options
      on_ready = function(hub)
        -- Called when hub is ready
      end,
      on_error = function(err)
        -- Called on errors
        -- TODO: english
        vim.notify(err, vim.log.levels.DEBUG)

        -- 提取包名信息的函数
        local function extract_package_name(config)
          if not config or not config.command or not config.args then return nil end

          local command, args = config.command, config.args

          if command == "npx" and #args >= 2 then
            -- 对于 npx 命令，第二个参数通常是包名
            return args[2] -- 对于 @scope/package 格式会完整保留
          elseif command == "uvx" and #args >= 1 then
            -- 对于 uvx 命令，第一个参数通常是包名
            return args[1]
          end

          return nil
        end

        -- 检查依赖是否已安装的函数
        local function check_dependency(command, package_name, server_name, callback)
          local check_cmd

          if command == "npx" then
            check_cmd = "npm list -g " .. package_name .. " --depth=0"
          elseif command == "uvx" then
            check_cmd = "uv pip show " .. package_name .. " --python ~/.mcp-hub/cache/.venv/bin/python"
          else
            return -- 不支持的命令类型
          end

          vim.notify("正在检查 " .. server_name .. " 依赖: " .. package_name, vim.log.levels.INFO)

          vim.fn.jobstart(check_cmd, {
            on_exit = function(_, code)
              -- 如果退出代码不为0，则表示依赖未安装
              callback(code ~= 0)
            end,
          })
        end

        -- 安装依赖的函数
        local function install_dependency(command, package_name, server_name)
          local install_cmd

          if command == "npx" then
            install_cmd = "npm install -g " .. package_name
          elseif command == "uvx" then
            install_cmd = "uv pip install " .. package_name .. " --python ~/.mcp-hub/cache/.venv/bin/python"
          else
            return -- 不支持的命令类型
          end

          vim.notify(package_name .. " 未安装，正在安装...", vim.log.levels.INFO)
          vim.notify("执行: " .. install_cmd, vim.log.levels.INFO)

          vim.fn.jobstart(install_cmd, {
            on_exit = function(_, code)
              if code == 0 then
                vim.notify(package_name .. " 已成功安装", vim.log.levels.INFO)

                -- 安装成功后尝试重启MCP Hub
                vim.defer_fn(function()
                  local hub = require("mcphub").get_hub_instance()
                  if hub then
                    hub:restart(nil)
                    vim.notify("已尝试重启 MCP Hub", vim.log.levels.INFO)
                  end
                end, 1000)
              else
                vim.notify(package_name .. " 安装失败，错误码: " .. code, vim.log.levels.ERROR)
              end
            end,
            on_stdout = function(_, data)
              if data and #data > 0 then
                vim.notify("安装输出: " .. table.concat(data, "\n"), vim.log.levels.DEBUG)
              end
            end,
            on_stderr = function(_, data)
              if data and #data > 0 then
                vim.notify("安装错误: " .. table.concat(data, "\n"), vim.log.levels.WARN)
              end
            end,
          })
        end

        -- 获取错误和配置信息
        local errors = require("mcphub").get_state().errors.items

        local server_configs = require("mcphub").get_state().servers_config

        -- Debug: 显示配置信息便于调试
        vim.notify(vim.inspect(server_configs), vim.log.levels.DEBUG)

        -- 收集出现错误的服务器名称
        local server_names = {}
        for _, err_item in ipairs(errors) do
          if err_item.details and err_item.details.server then table.insert(server_names, err_item.details.server) end
        end

        -- 处理出错的服务器
        if #server_names > 0 then
          vim.notify("检测到以下MCP服务器出错: " .. table.concat(server_names, ", "), vim.log.levels.WARN)

          -- 为每个出错的服务器检查并安装依赖
          for _, server_name in ipairs(server_names) do
            local config = server_configs[server_name]

            if not config then
              vim.notify("无法找到服务器 " .. server_name .. " 的配置信息", vim.log.levels.ERROR)
            else
              local package_name = extract_package_name(config)
              if package_name then
                check_dependency(config.command, package_name, server_name, function(needs_install)
                  if needs_install then install_dependency(config.command, package_name, server_name) end
                end)
              end
            end
          end
        end
      end,
      log = {
        level = vim.log.levels.WARN,
        to_file = false,
        file_path = nil,
        prefix = "MCPHub",
      },
    }
  end,
}
