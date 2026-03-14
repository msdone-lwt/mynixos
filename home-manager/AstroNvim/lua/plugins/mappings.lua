-- NOTE: mode
-- Normal 模式 (n): 正常模式，通常是你在编辑器中进行大部分操作的模式。
-- Visual 模式 (v): 可视模式，用于选择文本块。
-- Visual 模式 (x): 这里的 x 是 v 的一种变体，表示可视模式的字符选择。
-- Select 模式 (s): 选择模式，类似于可视模式，但用于替换选择的文本。
-- Operator-pending 模式 (o): 操作符等待模式，用于等待下一个操作符命令。
-- Insert 模式 (i): 插入模式，用于插入文本。
-- Command-line 模式 (c): 命令行模式，用于输入命令。
-- Terminal 模式 (t): 终端模式，用于在嵌入的终端中操作。
--
-- return {
--   "AstroNvim/astrocore",
--   ---@param opts AstroCoreOpts
--   opts = function(_, opts)
--     local astro = require "astrocore"
--     local get_icon = require("astroui").get_icon
--     -- initialize internally use mapping section titles
--     opts._map_sections = {
--       f = { desc = get_icon("Search", 1, true) .. "Find" },
--       p = { desc = get_icon("Package", 1, true) .. "Packages" },
--       l = { desc = get_icon("ActiveLSP", 1, true) .. "Language Tools" },
--       u = { desc = get_icon("Window", 1, true) .. "UI/UX" },
--       b = { desc = get_icon("Tab", 1, true) .. "Buffers" },
--       bs = { desc = get_icon("Sort", 1, true) .. "Sort Buffers" },
--       d = { desc = get_icon("Debugger", 1, true) .. "Debugger" },
--       g = { desc = get_icon("Git", 1, true) .. "Git" },
--       S = { desc = get_icon("Session", 1, true) .. "Session" },
--       t = { desc = get_icon("Terminal", 1, true) .. "Terminal" },
--     }
--
--     -- initialize mappings table
--     local maps = astro.empty_map_table()
--     local sections = assert(opts._map_sections)
--
--     -- Normal --
--     -- Standard Operations
--     maps.n["j"] = { "v:count == 0 ? 'gj' : 'j'", expr = true, silent = true, desc = "Move cursor down" }
--     maps.x["j"] = maps.n["j"]
--     maps.n["k"] = { "v:count == 0 ? 'gk' : 'k'", expr = true, silent = true, desc = "Move cursor up" }
--     maps.x["k"] = maps.n["k"]
--     maps.n["<Leader>w"] = { "<Cmd>w<CR>", desc = "Save" }
--     maps.n["<Leader>q"] = { "<Cmd>confirm q<CR>", desc = "Quit Window" }
--     maps.n["<Leader>Q"] = { "<Cmd>confirm qall<CR>", desc = "Exit AstroNvim" }
--     maps.n["<Leader>n"] = { "<Cmd>enew<CR>", desc = "New File" }
--     maps.n["<C-S>"] = { "<Cmd>silent! update! | redraw<CR>", desc = "Force write" }
--     -- TODO: remove insert save in AstroNvim v5 when used for signature help
--     maps.i["<C-S>"] = { "<Esc>" .. maps.n["<C-S>"][1], desc = maps.n["<C-S>"].desc }
--     maps.x["<C-S>"] = maps.i["<C-s>"]
--     maps.n["<C-Q>"] = { "<Cmd>q!<CR>", desc = "Force quit" }
--     maps.n["|"] = { "<Cmd>vsplit<CR>", desc = "Vertical Split" }
--     maps.n["\\"] = { "<Cmd>split<CR>", desc = "Horizontal Split" }
--     -- TODO: remove deprecated method check after dropping support for neovim v0.9
--     if not vim.ui.open then
--       local gx_desc = "Opens filepath or URI under cursor with the system handler (file explorer, web browser, …)"
--       maps.n["gx"] = { function() astro.system_open(vim.fn.expand "<cfile>") end, desc = gx_desc }
--       maps.x["gx"] = {
--         function()
--           local lines = vim.fn.getregion(vim.fn.getpos ".", vim.fn.getpos "v", { type = vim.fn.mode() })
--           astro.system_open(table.concat(vim.tbl_map(vim.trim, lines)))
--         end,
--         desc = gx_desc,
--       }
--     end
--     maps.n["<Leader>/"] = { "gcc", remap = true, desc = "Toggle comment line" }
--     maps.x["<Leader>/"] = { "gc", remap = true, desc = "Toggle comment" }
--
--     -- Neovim Default LSP Mappings
--     if vim.fn.has "nvim-0.11" ~= 1 then
--       maps.n["gra"] = { function() vim.lsp.buf.code_action() end, desc = "vim.lsp.buf.code_action()" }
--       maps.x["gra"] = { function() vim.lsp.buf.code_action() end, desc = "vim.lsp.buf.code_action()" }
--       maps.n["grn"] = { function() vim.lsp.buf.rename() end, desc = "vim.lsp.buf.rename()" }
--       maps.n["grr"] = { function() vim.lsp.buf.references() end, desc = "vim.lsp.buf.references()" }
--       -- --- TODO: AstroNvim v5 add backwards compatibility to follow neovim 0.11 mappings
--       -- maps.i["<C-S>"] = { function() vim.lsp.buf.signature_help() end, desc = "vim.lsp.buf.signature_help()" }
--     end
--
--     -- Plugin Manager
--     maps.n["<Leader>p"] = vim.tbl_get(sections, "p")
--     maps.n["<Leader>pi"] = { function() require("lazy").install() end, desc = "Plugins Install" }
--     maps.n["<Leader>ps"] = { function() require("lazy").home() end, desc = "Plugins Status" }
--     maps.n["<Leader>pS"] = { function() require("lazy").sync() end, desc = "Plugins Sync" }
--     maps.n["<Leader>pu"] = { function() require("lazy").check() end, desc = "Plugins Check Updates" }
--     maps.n["<Leader>pU"] = { function() require("lazy").update() end, desc = "Plugins Update" }
--     maps.n["<Leader>pa"] = { function() require("astrocore").update_packages() end, desc = "Update Lazy and Mason" }
--
--     -- Manage Buffers
--     maps.n["<Leader>c"] = { function() require("astrocore.buffer").close() end, desc = "Close buffer" }
--     maps.n["<Leader>C"] = { function() require("astrocore.buffer").close(0, true) end, desc = "Force close buffer" }
--     maps.n["]b"] = {
--       function() require("astrocore.buffer").nav(vim.v.count1) end,
--       desc = "Next buffer",
--     }
--     maps.n["[b"] = {
--       function() require("astrocore.buffer").nav(-vim.v.count1) end,
--       desc = "Previous buffer",
--     }
--     maps.n[">b"] = {
--       function() require("astrocore.buffer").move(vim.v.count1) end,
--       desc = "Move buffer tab right",
--     }
--     maps.n["<b"] = {
--       function() require("astrocore.buffer").move(-vim.v.count1) end,
--       desc = "Move buffer tab left",
--     }
--
--     maps.n["<Leader>b"] = vim.tbl_get(sections, "b")
--     maps.n["<Leader>bc"] =
--       { function() require("astrocore.buffer").close_all(true) end, desc = "Close all buffers except current" }
--     maps.n["<Leader>bC"] = { function() require("astrocore.buffer").close_all() end, desc = "Close all buffers" }
--     maps.n["<Leader>bl"] =
--       { function() require("astrocore.buffer").close_left() end, desc = "Close all buffers to the left" }
--     maps.n["<Leader>bp"] = { function() require("astrocore.buffer").prev() end, desc = "Previous buffer" }
--     maps.n["<Leader>br"] =
--       { function() require("astrocore.buffer").close_right() end, desc = "Close all buffers to the right" }
--     maps.n["<Leader>bs"] = vim.tbl_get(sections, "bs")
--     maps.n["<Leader>bse"] = { function() require("astrocore.buffer").sort "extension" end, desc = "By extension" }
--     maps.n["<Leader>bsr"] = { function() require("astrocore.buffer").sort "unique_path" end, desc = "By relative path" }
--     maps.n["<Leader>bsp"] = { function() require("astrocore.buffer").sort "full_path" end, desc = "By full path" }
--     maps.n["<Leader>bsi"] = { function() require("astrocore.buffer").sort "bufnr" end, desc = "By buffer number" }
--     maps.n["<Leader>bsm"] = { function() require("astrocore.buffer").sort "modified" end, desc = "By modification" }
--
--     maps.n["<Leader>l"] = vim.tbl_get(sections, "l")
--     maps.n["<Leader>ld"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }
--     local function diagnostic_goto(dir, severity)
--       local go = vim.diagnostic["goto_" .. (dir and "next" or "prev")]
--       if type(severity) == "string" then severity = vim.diagnostic.severity[severity] end
--       return function() go { severity = severity } end
--     end
--     -- TODO: Remove mapping after dropping support for Neovim v0.10, it's automatic
--     if vim.fn.has "nvim-0.11" == 0 then
--       maps.n["[d"] = { diagnostic_goto(false), desc = "Previous diagnostic" }
--       maps.n["]d"] = { diagnostic_goto(true), desc = "Next diagnostic" }
--     end
--     maps.n["[e"] = { diagnostic_goto(false, "ERROR"), desc = "Previous error" }
--     maps.n["]e"] = { diagnostic_goto(true, "ERROR"), desc = "Next error" }
--     maps.n["[w"] = { diagnostic_goto(false, "WARN"), desc = "Previous warning" }
--     maps.n["]w"] = { diagnostic_goto(true, "WARN"), desc = "Next warning" }
--     -- TODO: Remove mapping after dropping support for Neovim v0.9, it's automatic
--     if vim.fn.has "nvim-0.10" == 0 then
--       maps.n["<C-W>d"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }
--       maps.n["<C-W><C-D>"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }
--     end
--     maps.n["gl"] = { function() vim.diagnostic.open_float() end, desc = "Hover diagnostics" }
--
--     -- Navigate tabs
--     maps.n["]t"] = { function() vim.cmd.tabnext() end, desc = "Next tab" }
--     maps.n["[t"] = { function() vim.cmd.tabprevious() end, desc = "Previous tab" }
--
--     -- Split navigation
--     maps.n["<C-H>"] = { "<C-w>h", desc = "Move to left split" }
--     maps.n["<C-J>"] = { "<C-w>j", desc = "Move to below split" }
--     maps.n["<C-K>"] = { "<C-w>k", desc = "Move to above split" }
--     maps.n["<C-L>"] = { "<C-w>l", desc = "Move to right split" }
--     maps.n["<C-Up>"] = { "<Cmd>resize -2<CR>", desc = "Resize split up" }
--     maps.n["<C-Down>"] = { "<Cmd>resize +2<CR>", desc = "Resize split down" }
--     maps.n["<C-Left>"] = { "<Cmd>vertical resize -2<CR>", desc = "Resize split left" }
--     maps.n["<C-Right>"] = { "<Cmd>vertical resize +2<CR>", desc = "Resize split right" }
--
--     maps.n["]q"] = { vim.cmd.cnext, desc = "Next quickfix" }
--     maps.n["[q"] = { vim.cmd.cprev, desc = "Previous quickfix" }
--     maps.n["]Q"] = { vim.cmd.clast, desc = "End quickfix" }
--     maps.n["[Q"] = { vim.cmd.cfirst, desc = "Beginning quickfix" }
--
--     maps.n["]l"] = { vim.cmd.lnext, desc = "Next loclist" }
--     maps.n["[l"] = { vim.cmd.lprev, desc = "Previous loclist" }
--     maps.n["]L"] = { vim.cmd.llast, desc = "End loclist" }
--     maps.n["[L"] = { vim.cmd.lfirst, desc = "Beginning loclist" }
--
--     -- Stay in indent mode
--     maps.v["<S-Tab>"] = { "<gv", desc = "Unindent line" }
--     maps.v["<Tab>"] = { ">gv", desc = "Indent line" }
--
--     -- Improved Terminal Navigation
--     maps.t["<C-H>"] = { "<Cmd>wincmd h<CR>", desc = "Terminal left window navigation" }
--     maps.t["<C-J>"] = { "<Cmd>wincmd j<CR>", desc = "Terminal down window navigation" }
--     maps.t["<C-K>"] = { "<Cmd>wincmd k<CR>", desc = "Terminal up window navigation" }
--     maps.t["<C-L>"] = { "<Cmd>wincmd l<CR>", desc = "Terminal right window navigation" }
--
--     maps.n["<Leader>u"] = vim.tbl_get(sections, "u")
--     -- Custom menu for modification of the user experience
--     maps.n["<Leader>uA"] = { function() require("astrocore.toggles").autochdir() end, desc = "Toggle rooter autochdir" }
--     maps.n["<Leader>ub"] = { function() require("astrocore.toggles").background() end, desc = "Toggle background" }
--     maps.n["<Leader>ud"] = { function() require("astrocore.toggles").diagnostics() end, desc = "Toggle diagnostics" }
--     maps.n["<Leader>ug"] = { function() require("astrocore.toggles").signcolumn() end, desc = "Toggle signcolumn" }
--     maps.n["<Leader>u>"] = { function() require("astrocore.toggles").foldcolumn() end, desc = "Toggle foldcolumn" }
--     maps.n["<Leader>ui"] = { function() require("astrocore.toggles").indent() end, desc = "Change indent setting" }
--     maps.n["<Leader>ul"] = { function() require("astrocore.toggles").statusline() end, desc = "Toggle statusline" }
--     maps.n["<Leader>un"] = { function() require("astrocore.toggles").number() end, desc = "Change line numbering" }
--     maps.n["<Leader>uN"] =
--       { function() require("astrocore.toggles").notifications() end, desc = "Toggle Notifications" }
--     maps.n["<Leader>up"] = { function() require("astrocore.toggles").paste() end, desc = "Toggle paste mode" }
--     maps.n["<Leader>us"] = { function() require("astrocore.toggles").spell() end, desc = "Toggle spellcheck" }
--     maps.n["<Leader>uS"] = { function() require("astrocore.toggles").conceal() end, desc = "Toggle conceal" }
--     maps.n["<Leader>ut"] = { function() require("astrocore.toggles").tabline() end, desc = "Toggle tabline" }
--     maps.n["<Leader>uu"] = { function() require("astrocore.toggles").url_match() end, desc = "Toggle URL highlight" }
--     maps.n["<Leader>uw"] = { function() require("astrocore.toggles").wrap() end, desc = "Toggle wrap" }
--     maps.n["<Leader>uy"] =
--       { function() require("astrocore.toggles").buffer_syntax() end, desc = "Toggle syntax highlight" }
--
--     opts.mappings = maps
--   end,
-- }
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        -- first key is the mode
        n = {
          -- mappings seen under group name "Buffer"
          ["<leader><enter>"] = {
            ":silent .w !xargs -0r tmux send -t 1 -l <cr>",
            desc = "Tmux sends command to pane 1",
          },
          ["<leader>s"] = { "/<C-r>*<CR>", desc = "Search the contents of register *" },
          ["<leader>L"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
          ["<leader>H"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
          ["L"] = { "$" },
          ["H"] = { "^" },
          -- [":"] = { function() require("snacks").toggle.dim() end, desc = "input" },
          ["<Leader>bD"] = {
            function()
              require("astroui.status").heirline.buffer_picker(
                function(bufnr) require("astrocore.buffer").close(bufnr) end
              )
            end,
            desc = "Pick to close",
          },
          -- tables with the `name` key will be registered with which-key if it's installed
          -- this is useful for naming menus
          ["<Leader>b"] = { name = "Buffers" },
          -- NOTE: Flash
          ["<Leader><Leader>"] = { name = " Flash" },
          -- quick save
          -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command         -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
          ["<leader><leader>w"] = { function() require("flash").jump {} end, desc = "Flash" },
          ["<leader><leader>W"] = { function() require("flash").treesitter() end, desc = "Flash Treesitter" },
          -- NOTE: Overseer
          -- ["<leader>r"] = { ":RunCode<CR>", desc = "code-runner.nvim - RunCode" },
          ["<leader>r"] = { "<cmd>Overseer<CR>", desc = " Overseer" },
          ["<leader>rr"] = { "<cmd>OverseerRun<CR>", desc = "List overseer run templates" },
          ["<leader>rt"] = { "<cmd>OverseerToggle<CR>", desc = "Toggle overseer task list" },
          -- NOTE: Avante
          -- ["<Leader>a"] = { name = "🤖 Avante" }, -- 其他 key mappings 在  ~/.config/nvim/lua/plugins/avante.nvim.lua
          -- NOTE: marks
          ["<Leader>m"] = { name = " Marks" },
          ["<Leader>mt"] = { "<cmd>MarksToggleSigns<CR>", desc = "Toggle marks" },
          ["<Leader>ml"] = { "<cmd>MarksListBuf<CR>", desc = "List buffer marks" },
          ["<Leader>mL"] = { "<cmd>MarksListGlobal<CR>", desc = "List global marks" },
          ["<Leader>mg"] = {
            function()
              vim.ui.input({ prompt = "输入书签组名: " }, function(input)
                if input then vim.cmd("BookmarksList " .. input) end
              end)
            end,
            desc = "查询指定 group_name 的书签",
          },
          ["<Leader>mG"] = { "<cmd>BookmarksListAll<CR>", desc = "查询所有 group 的书签" },
          ["<leader>mp"] = {
            function()
              vim.ui.input({ prompt = "press letter mark to preview:" }, function(input)
                if input then vim.cmd([[execute "normal \<Plug>(Marks-preview)]] .. input .. [[\<CR>"]]) end
              end)
            end,
            desc = "press letter mark to preview",
          },
          ["m0"] = {
            function()
              vim.ui.input({ prompt = "添加注释,没有留空:" }, function(input)
                if input then
                  vim.cmd([[execute "normal \<Plug>(Marks-set-bookmark0)]] .. input .. [[\<CR>"]])
                else
                  vim.cmd [[execute "normal \<Plug>(Marks-set-bookmark0)\<CR>"]]
                end
              end)
            end,
            desc = "bookmarks",
          },
        },
        i = {
          ["<C-h>"] = { "<Cmd>wincmd h<CR>", desc = "Move to left split" },
          ["<C-j>"] = { "<Cmd>wincmd j<CR>", desc = "Move to below split" },
          ["<C-k>"] = { "<Cmd>wincmd k<CR>", desc = "Move to above split" },
          ["<C-l>"] = { "<Cmd>wincmd l<CR>", desc = "Move to right split" },
          ["<C-v>"] = { "<C-[>pa", desc = "paste" },
          -- augment
          -- ["<CR>"] = { "<cmd>lua vim.call('augment#Accept', '\\n')<cr>", desc = "Augment Accept" },
          -- ["<M-m>"] = { "<cmd>lua vim.call('augment#Accept', '\\n')<cr>", desc = "Augment Accept" },
          -- ["<enter>"] = { "<cmd>lua vim.call('augment#Accept', '\\n')<cr>", desc = "Augment Accept" },
        },
        x = {
          ["<Leader><Leader>"] = { name = " Flash" },
          ["<leader><leader>w"] = { function() require("flash").jump() end, desc = "Flash" },
          ["<leader><leader>W"] = { function() require("flash").treesitter() end, desc = "Flash Treesitter" },
          ["R"] = { function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
        },
        o = {
          ["<Leader><Leader>"] = { name = " Flash" },
          ["<leader><leader>w"] = { function() require("flash").jump() end, desc = "Flash" },
          ["<leader><leader>W"] = { function() require("flash").treesitter() end, desc = "Flash Treesitter" },
          ["r"] = { function() require("flash").remote() end, desc = "Remote Flash" },
          ["R"] = { function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
        },
        t = {
          -- setting a mapping to false will disable it
          -- ["<esc>"] = false,
          ["jj"] = false,
          -- ["jk"] = false,
          ["<leader>q"] = { "<Cmd>confirm q<CR>", desc = "Quit Window" },
        },
        v = {
          ["p"] = { "pgvy", desc = "paste" },
          ["L"] = { "$h" },
          ["H"] = { "^" },
          ["<Leader>a"] = { name = "🤖 Avante" }, -- 其他 key mappings 在  ~/.config/nvim/lua/plugins/avante.nvim.lua
        },
        c = {
          ["<leader><leader>w"] = { function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
      },
    },
  },
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      mappings = {
        n = {
          -- this mapping will only be set in buffers with an LSP attached
          K = {
            function() vim.lsp.buf.hover() end,
            desc = "Hover symbol details",
          },
          -- condition for only server with declaration capabilities
          -- NOTE: :  https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#general
          --  删除 nvim-tree/nvim-web-devicons
          gd = {
            function() require("snacks").picker.lsp_definitions() end,
            desc = "Goto Definition",
          },
          gr = {
            function() require("snacks").picker.lsp_references() end,
            desc = "Show LSP References",
          },
        },
      },
    },
  },
}
