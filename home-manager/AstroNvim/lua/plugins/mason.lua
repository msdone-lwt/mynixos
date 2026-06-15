-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Mason

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        "ruff",
        "stylua",
        "clangd",
        "selene",
        "nixfmt",
        "neocmakelsp",
        "basedpyright",
        "lua-language-server",
        "deno",
        "js-debug-adapter",
        "codelldb",
        "debugpy",
        "black",
        "copilot-language-server",
        "isort",
        "json-lsp",
        "marksman",
        "nil",
        "taplo",
        "vtsls",
        "yaml-language-server",
        "actionlint",
        "yamlfmt",
        "rust-analyzer",
        "qmlls",
        "ast-grep"
      },
      -- 启动时自动安装缺失的工具
      run_on_start = true,
    },
  },
}
