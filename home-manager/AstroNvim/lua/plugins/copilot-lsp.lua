-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- NOTE: 需要安装 copilot-language-server: npm install @github/copilot-language-server@1.381.0

-- Customize copilot-lsp

function callback()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = vim.b[bufnr].nes_state
  if state then
    -- Try to jump to the start of the suggestion edit.
    -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
    local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
      or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
    return nil
  else
    -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
    return "<C-i>"
  end
end
-- @type LazySpec
return {
  "copilotlsp-nvim/copilot-lsp",
  init = function()
    vim.g.copilot_nes_debounce = 200
    vim.lsp.enable "copilot_ls"
    vim.keymap.set("n", "<M-m>", function() return callback() end, { desc = "Accept Copilot NES suggestion", expr = true })
    vim.keymap.set("i", "<M-m>", function() return callback() end, { desc = "Accept Copilot NES suggestion", expr = true })
  end,
}
