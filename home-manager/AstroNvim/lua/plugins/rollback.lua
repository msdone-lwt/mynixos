if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
--- Function to get all downloaded plugin names from lazy.nvim
-- @return table A list of plugin names in "author/repo_name" format.
function GetLazyPluginNames()
  local plugin_names = {}

  -- Check if lazy is loaded and its 'plugins' member is a function
  if not (package.loaded.lazy and type(require("lazy").plugins) == "function") then
    vim.notify("lazy.nvim is not loaded or its 'plugins' is not a function.", vim.log.levels.WARN)
    return plugin_names -- Return empty list early
  end

  local list_of_plugin_objects = require("lazy").plugins()
  -- Ensure plugins() returned a table
  if type(list_of_plugin_objects) ~= "table" then
    vim.notify("lazy.nvim plugins() did not return a table of plugin objects.", vim.log.levels.WARN)
    return plugin_names -- Return empty list early
  end

  -- Iterate over the list of plugin objects
  for _, plugin_obj in ipairs(list_of_plugin_objects) do
    if type(plugin_obj) == "table" then
      local spec1 = plugin_obj[1] -- Primary spec string, e.g., "author/repo_name"

      -- Check if spec1 is a string and contains '/' (the "author/repo_name" format)
      if type(spec1) == "string" and string.find(spec1, "/", 1, true) then
        table.insert(plugin_names, spec1)
      else
        -- If spec1 is not in "author/plugin_name" format, notify and skip.
        local plugin_identifier = "unknown plugin"
        if type(plugin_obj.name) == "string" then
          plugin_identifier = plugin_obj.name
        elseif type(spec1) == "string" then
          -- Use spec1 as identifier if it was a string but not in the correct format
          plugin_identifier = spec1
        end

        -- Use vim.inspect for a readable representation of spec1; it handles nil.
        local spec1_representation = vim.inspect(spec1)

        vim.notify(
          string.format(
            "Skipping plugin '%s' as its primary spec (%s) is not in 'author/plugin_name' format.",
            plugin_identifier,
            spec1_representation
          ),
          vim.log.levels.INFO
        )
      end
    else
      -- Notify if an item in the plugin list is not a table
      vim.notify(
        string.format("Plugin object item in list is not a table: %s", vim.inspect(plugin_obj)),
        vim.log.levels.WARN
      )
    end
  end
  return plugin_names
end

-- Example usage:
-- vim.notify(vim.inspect(GetLazyPluginNames()))

--- Helper function to execute git commands within the Neovim config directory.
-- @param config_dir string: The path to the Neovim configuration directory.
-- @param git_cmd_args string: The arguments to pass to the git command (e.g., "show HEAD:filename").
-- @return string|nil: The stdout of the command if successful.
-- @return string|nil: An error message key if failed ("popen_failed", "git_command_failed", "file_not_in_head"), or nil if successful.
local function execute_git_command(config_dir, git_cmd_args)
  local command_str = string.format("git -C %s %s", vim.fn.shellescape(config_dir), git_cmd_args)
  local f = io.popen(command_str, "r")
  if not f then
    vim.notify("Failed to popen git command: " .. command_str, vim.log.levels.ERROR)
    return nil, "popen_failed"
  end
  local output = f:read "*a"
  local ok, reason, status = f:close()

  if not ok then
    -- For `git show HEAD:nonexistentfile`, git exits with 128.
    if git_cmd_args:match "^show HEAD:" and status == 128 then
      return "{}", "file_not_in_head" -- Return empty JSON object string, specific "error"
    end
    vim.notify(
      string.format(
        "Git command failed (reason: %s, status: %s): %s\nOutput: %s",
        reason or "?",
        status or "?",
        command_str,
        output or "<empty>"
      ),
      vim.log.levels.WARN
    )
    return nil, string.format("git_command_failed: %s %s", reason or "?", status or "?")
  end
  return output, nil -- Success, no error key
end

--- Checks lazy-lock.json for plugins that were modified (commit changed) or deleted compared to HEAD.
-- @return table|nil A list of plugins. Each plugin is a table: `{"author/repo_name", commit="OLD_commit_hash"}`.
--                   Returns nil if no such changes are found or if an error occurs.
function GetChangedOrDeletedLockedPlugins()
  local config_dir = vim.fn.stdpath "config"
  local lockfile_name = "lazy-lock.json" -- Relative to config_dir for git commands
  local lockfile_path_absolute = config_dir .. "/" .. lockfile_name

  -- 1. Get content of lazy-lock.json from HEAD (previous state)
  local old_content_str, err_key_old =
    execute_git_command(config_dir, "show HEAD:" .. vim.fn.shellescape(lockfile_name))

  if err_key_old and err_key_old ~= "file_not_in_head" then
    vim.notify("Error getting lazy-lock.json from HEAD: " .. err_key_old, vim.log.levels.ERROR)
    return nil
  end
  -- If err_key_old is "file_not_in_head", old_content_str is "{}", which is desired.

  -- 2. Get content of lazy-lock.json from the current workspace
  local current_content_str
  if vim.fn.filereadable(lockfile_path_absolute) == 1 then
    local lines = vim.fn.readfile(lockfile_path_absolute)
    current_content_str = table.concat(lines, "\n")
  else
    current_content_str = "{}" -- File is deleted or not readable in workspace
  end

  -- 3. Decode JSON content
  local old_locked_plugins
  local temp_old = vim.fn.json_decode(old_content_str or "{}") -- Ensure non-nil string
  if type(temp_old) == "table" then
    old_locked_plugins = temp_old
  else
    old_locked_plugins = {}
  end

  local current_locked_plugins
  local temp_current = vim.fn.json_decode(current_content_str or "{}")
  if type(temp_current) == "table" then
    current_locked_plugins = temp_current
  else
    current_locked_plugins = {}
  end

  -- 4. Prepare mapping from repo_name to "author/repo_name" using GetLazyPluginNames
  local all_plugin_specs = GetLazyPluginNames() -- This function is already defined above
  local repo_to_full_spec = {}
  if type(all_plugin_specs) == "table" then
    for _, spec in ipairs(all_plugin_specs) do
      if type(spec) == "string" then
        -- Extracts "repo_name" or "repo_name.nvim" from "author/repo_name.nvim"
        local repo_name_part = spec:match "/([^/]+)$"
        if repo_name_part then
          repo_to_full_spec[repo_name_part] = spec
          -- Handle cases where lazy-lock.json might not have .nvim suffix
          local repo_name_no_suffix = repo_name_part:gsub("%.nvim$", "")
          if repo_name_no_suffix ~= repo_name_part then repo_to_full_spec[repo_name_no_suffix] = spec end
        end
      end
    end
  end

  -- 5. Compare old and current plugins to find changes/deletions
  local changed_plugins_list = {}
  for repo_name_from_lock, old_data in pairs(old_locked_plugins) do
    if type(old_data) == "table" and old_data.commit then
      local old_commit = old_data.commit
      local current_data = current_locked_plugins[repo_name_from_lock]

      -- A plugin is considered changed/deleted if:
      -- a) It's not in the current lockfile OR
      -- b) It is in the current lockfile, but its commit hash is different.
      if not current_data or type(current_data) ~= "table" or current_data.commit ~= old_commit then
        local full_spec = repo_to_full_spec[repo_name_from_lock]

        -- Attempt to match without .nvim suffix if direct match failed
        if not full_spec and repo_name_from_lock:match "%.nvim$" then
          full_spec = repo_to_full_spec[repo_name_from_lock:gsub("%.nvim$", "")]
        elseif not full_spec and not repo_name_from_lock:match "%.nvim$" then
          full_spec = repo_to_full_spec[repo_name_from_lock .. ".nvim"]
        end

        if not full_spec then
          -- Fallback: if repo_name_from_lock itself is already in "author/repo_name" format
          if type(repo_name_from_lock) == "string" and string.find(repo_name_from_lock, "/", 1, true) then
            full_spec = repo_name_from_lock
          end
        end

        if full_spec then
          table.insert(changed_plugins_list, { full_spec, commit = old_commit })
        else
          vim.notify(
            string.format(
              "Skipping locked plugin '%s': Cannot determine its full 'author/repo_name' spec from available plugins.",
              repo_name_from_lock
            ),
            vim.log.levels.INFO
          )
        end
      end
    end
  end

  -- 6. Return results
  if #changed_plugins_list == 0 then
    return nil -- No relevant changes found
  end

  return changed_plugins_list
end

-- Example usage for the new function (optional, for testing):
vim.defer_fn(function()
  local changed = GetChangedOrDeletedLockedPlugins()
  if changed then
    vim.notify("Changed/deleted plugins in lazy-lock.json (compared to HEAD):")
    vim.notify(vim.inspect(changed))
  else
    vim.notify("No changed/deleted plugins found in lazy-lock.json (compared to HEAD), or an error occurred.")
  end
end, 1000)
