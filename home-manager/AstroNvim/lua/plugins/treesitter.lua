-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      ensure_installed = {
        "vim",
        "lua",
        -- add more arguments for adding more treesitter parsers
      },
      highlight = true, -- enable/disable treesitter based highlighting
      indent = true, -- enable/disable treesitter based indentation
      auto_install = true, -- enable/disable automatic installation of detected languages
      textobjects = {
        select = {
          select_textobject = {
            ["ak"] = { query = "@block.outer", desc = "around block" },
          },
        },
      },
    },
  },
}
