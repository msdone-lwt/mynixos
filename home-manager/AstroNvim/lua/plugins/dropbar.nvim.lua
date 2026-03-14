-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize dropbar.nvim

-- @type LazySpec

return {
  "Bekaboo/dropbar.nvim",
  -- 锁定在特定版本，不允许升级(在此之后的提交需要 V0.11.0 版本 nvim)
  -- commit = "873ba43f83398fd0e28880cf98fd89e6ce667c51",
  -- optional, but required for fuzzy finder support
  dependencies = {
    "nvim-telescope/telescope-fzf-native.nvim",
  },
  config = function() end,
}
