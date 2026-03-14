-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize marks.nvim

-- @type LazySpec

return {
  "chentoast/marks.nvim",
  event = "VeryLazy",
  opts = {
    -- 是否映射键绑定。默认 true
    default_mappings = true,
    -- 显示的内置标记。默认 {}
    builtin_marks = {},
    -- 移动是否循环回缓冲区的开始/结束。默认 true
    cyclic = true,
    -- 是否在修改大写标记后强制更新 shada 文件。默认 false
    force_write_shada = false,
    -- 重绘符号/重新计算标记位置的频率（以毫秒为单位）。
    -- 值越高，性能越好，但可能会引起视觉延迟，
    -- 值越低，可能会导致性能损失。默认 150。
    refresh_interval = 250,
    -- 各类型标记的符号优先级 - 内置标记、大写标记、 小写标记和书签。
    -- 可以是包含所有/不包含任何键的表，或者单个数字，应用于所有标记。
    -- 默认 10。
    sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
    -- 禁用特定文件类型的标记跟踪。默认 {}
    excluded_filetypes = {
      "DressingInput",
      "AvanteInput",
      "neo-tree",
      "neo-tree-popup",
      "neo-tree-preview",
      "mcphub"
    },
    -- 禁用特定缓冲区类型的标记跟踪。默认 {}
    excluded_buftypes = {
    },
    -- marks.nvim 允许您配置最多 10 个书签组，每个组有自己的符号/虚拟文本。
    -- 书签可用于将位置分组，并在多个缓冲区之间快速移动。
    -- 默认符号是 '!@#$%^&*()'（从 0 到 9），默认虚拟文本是""。
    bookmark_0 = {
      sign = "⚑",
      virt_text = "hello world",
      -- 明确提示在设置此组书签时的虚拟行注释。默认 false。
      annotate = true,
    },
    mappings = {
      set_next = false
    },
  },
}
-- mx 设置标记 x
-- m, 设置下一个可用的字母标记（小写）
-- m; 切换当前行的下一个可用标记
-- dmx 删除标记 x
-- dm- 删除当前行的所有标记
-- dm<space> 删除当前缓冲区的所有标记
-- m] 移动到下一个标记
-- m[ 移动到上一个标记
-- m: 预览标记。此操作会提示选择一个特定的标记进行预览；按下 <回车> 预览下一个标记。
-- m[0-9] 从书签组[0-9]添加书签。
-- dm[0-9] 删除书签组[0-9]中的所有书签。
-- m} 移动到下一个与光标下书签类型相同的书签。跨缓冲区生效。
-- m{ 移动到上一个与光标下书签类型相同的书签。跨缓冲区生效。
-- dm= 删除光标下方的书签。
