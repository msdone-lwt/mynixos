-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

return {
    "OXY2DEV/helpview.nvim",
    lazy = true,

    -- In case you still want to lazy load
    ft = "help",

    dependencies = {
        "nvim-treesitter/nvim-treesitter"
    }
}
