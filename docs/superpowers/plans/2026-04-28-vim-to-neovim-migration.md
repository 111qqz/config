# Vim → Neovim 迁移实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 `~/.vimrc` 的日常使用迁移到一份现代化的 Neovim 配置（kickstart 派生、模块化、Lua），同时保留旧 `.vimrc` 作为远程裸机/容器的兜底。

**Architecture:** 在 repo 内的 `nvim/` 目录中放完整 nvim 配置，通过软链 `~/.config/nvim → config/nvim` 接管。一文件一插件、lazy 加载，所有 LSP/格式化/lint 工具由 mason 自动安装到 `~/.local/share/nvim/mason/`。

**Tech Stack:** Neovim ≥ 0.10、lazy.nvim、mason.nvim、nvim-lspconfig、blink.cmp、nvim-treesitter、telescope.nvim、conform.nvim、nvim-lint、tokyonight.nvim、oil.nvim、gitsigns.nvim、lualine.nvim、avante.nvim

**Spec reference:** `docs/superpowers/specs/2026-04-28-vim-to-neovim-migration-design.md`

---

## 文件结构（全部本计划新增）

```
config/nvim/
├── init.lua
├── lua/
│   ├── options.lua
│   ├── keymaps.lua
│   ├── autocmds.lua
│   └── plugins/
│       ├── colorscheme.lua
│       ├── treesitter.lua
│       ├── lsp.lua
│       ├── completion.lua
│       ├── telescope.lua
│       ├── gitsigns.lua
│       ├── lualine.lua
│       ├── oil.lua
│       ├── autopairs.lua
│       ├── conform.lua
│       ├── lint.lua
│       ├── whichkey.lua
│       ├── log-highlighting.lua
│       └── avante.lua
└── ftplugin/
    ├── cpp.lua
    └── c.lua
```

**删除**：`config/.ycm_extra_conf.py`、`config/acm_vimrc`
**保留不动**：`config/.vimrc`（vim 兜底）

---

## 关于"测试"

nvim 配置无传统单元测试。每个任务的"验证步"是一条 headless 命令：

```bash
nvim --headless "+lua print('OK: ' .. <module>)" +qa 2>&1
```

或交互检查（开 nvim 看效果）。**关键防回归命令**贯穿整个计划：

```bash
nvim --headless "+lua require('lazy').sync({ wait = true })" +qa 2>&1 | tail -20
```

---

## Task 1：创建目录骨架 + 入口 init.lua + lazy.nvim 自举

**Files:**
- Create: `config/nvim/init.lua`
- Create: `config/nvim/lua/` (空目录，本任务先建好)
- Create: `config/nvim/lua/plugins/` (同上)
- Create: `config/nvim/ftplugin/` (同上)

- [ ] **Step 1：建目录**

```bash
mkdir -p config/nvim/lua/plugins config/nvim/ftplugin
```

- [ ] **Step 2：写 init.lua**

`config/nvim/init.lua`：
```lua
-- leader 必须在加载任何插件之前设置
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- 基础选项 + 键位 + autocmds
require('options')
require('keymaps')
require('autocmds')

-- 自举 lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
    }, true, {})
    error('lazy.nvim clone failed')
  end
end
vim.opt.rtp:prepend(lazypath)

-- 加载 lua/plugins/ 下所有文件
require('lazy').setup('plugins', {
  change_detection = { notify = false },
  install = { colorscheme = { 'tokyonight', 'habamax' } },
})
```

- [ ] **Step 3：先写最小占位的 options/keymaps/autocmds 让 init 能加载**

`config/nvim/lua/options.lua`：
```lua
-- 占位文件，Task 2 会填充
```

`config/nvim/lua/keymaps.lua`：
```lua
-- 占位文件，Task 3 会填充
```

`config/nvim/lua/autocmds.lua`：
```lua
-- 占位文件，Task 4 会填充
```

- [ ] **Step 4：先建一个软链让 nvim 能找到这份配置**

```bash
ln -sfT "$(pwd)/config/nvim" ~/.config/nvim
ls -la ~/.config/nvim
```

预期：`~/.config/nvim` 是指向 `<repo>/config/nvim` 的软链。

- [ ] **Step 5：验证 nvim 能启动并自举 lazy.nvim**

```bash
nvim --headless "+qa" 2>&1
```

预期：第一次运行会克隆 lazy.nvim 到 `~/.local/share/nvim/lazy/lazy.nvim`，无错误退出。

```bash
ls ~/.local/share/nvim/lazy/lazy.nvim/lazy.lua
```

预期：文件存在。

- [ ] **Step 6：commit**

```bash
git add config/nvim/
git commit -m "feat(nvim): bootstrap init.lua and lazy.nvim"
```

---

## Task 2：填充 lua/options.lua

**Files:**
- Modify: `config/nvim/lua/options.lua`

- [ ] **Step 1：写 options.lua**

```lua
local opt = vim.opt

-- 显示
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.ruler = true
opt.signcolumn = 'yes'
opt.termguicolors = true
opt.showmode = false  -- lualine 已显示模式

-- 搜索（保持旧 vimrc 行为）
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- 编辑
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

-- 性能
opt.updatetime = 100  -- 旧 vimrc：vim-signify 需要

-- 持久化
opt.backup = true
opt.undofile = true

-- 保持旧 vimrc 的 CJK 编码兼容
opt.fileencodings = 'utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1'
opt.encoding = 'utf-8'

-- 临时目录（保持旧 vimrc 把 ~/tmp 作为 backup/swap/undo 目录）
local tmpdir = vim.fn.expand('~/tmp')
vim.fn.mkdir(tmpdir, 'p')
opt.backupdir:remove('.')
opt.backupdir:prepend(tmpdir .. '//')
opt.directory:remove('.')
opt.directory:prepend(tmpdir .. '//')
opt.undodir:remove('.')
opt.undodir:prepend(tmpdir .. '//')

-- splits
opt.splitright = true
opt.splitbelow = true

-- 鼠标支持（远程贴图、滚动）
opt.mouse = 'a'

-- clipboard：与系统剪贴板共享（Wayland 下需要 wl-clipboard）
opt.clipboard = 'unnamedplus'
```

- [ ] **Step 2：验证**

```bash
nvim --headless "+lua print(vim.opt.relativenumber:get())" "+qa" 2>&1
```

预期：输出 `true`。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/options.lua
git commit -m "feat(nvim): port editor options from .vimrc"
```

---

## Task 3：填充 lua/keymaps.lua

**Files:**
- Modify: `config/nvim/lua/keymaps.lua`

- [ ] **Step 1：写 keymaps.lua（旧 vimrc 全部通用键位）**

```lua
local map = vim.keymap.set

-- ==== 旧 vimrc 键位 ====

-- 切 tab
map('n', '<C-J>', ':tabp<CR>', { silent = true, desc = 'prev tab' })
map('n', '<C-K>', ':tabn<CR>', { silent = true, desc = 'next tab' })

-- 切 buffer（带自动保存）
local function save_then(cmd)
  return function()
    if vim.bo.modifiable and not vim.bo.readonly and vim.bo.modified then
      vim.cmd.write()
    end
    vim.cmd(cmd)
  end
end
map('n', '<Tab>', save_then('bnext'), { silent = true, desc = 'next buffer (autosave)' })
map('n', '<S-Tab>', save_then('bprevious'), { silent = true, desc = 'prev buffer (autosave)' })

-- F4：高亮所有行尾空格（codecc 用）
map('n', '<F4>', '/\\s\\+$<CR>', { desc = 'highlight trailing whitespace' })

-- 阻止方向键的训练
local arrow_hints = { ['<Left>'] = 'h', ['<Right>'] = 'l', ['<Up>'] = 'k', ['<Down>'] = 'j' }
for key, hint in pairs(arrow_hints) do
  map('n', key, ':echoe "Use ' .. hint .. '"<CR>', { silent = true })
  map('i', key, '<ESC>:echoe "Use ' .. hint .. '"<CR>', { silent = true })
end

-- ==== 新增：常用 nvim 习惯 ====

-- 清搜索高亮
map('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- 把选区上下移
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'move selection down' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'move selection up' })
```

- [ ] **Step 2：验证**

```bash
nvim --headless "+lua local m = vim.fn.maparg('<Tab>', 'n'); print(#m > 0 and 'OK' or 'MISS')" "+qa" 2>&1
```

预期：输出 `OK`。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/keymaps.lua
git commit -m "feat(nvim): port general keymaps from .vimrc"
```

---

## Task 4：填充 lua/autocmds.lua

**Files:**
- Modify: `config/nvim/lua/autocmds.lua`

- [ ] **Step 1：写 autocmds.lua**

```lua
local augroup = vim.api.nvim_create_augroup('userconfig', { clear = true })

-- 旧 vimrc：text 文件 textwidth=78
vim.api.nvim_create_autocmd('FileType', {
  group = augroup,
  pattern = 'text',
  callback = function() vim.bo.textwidth = 78 end,
})

-- 打开文件时跳到上次离开的位置
vim.api.nvim_create_autocmd('BufReadPost', {
  group = augroup,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 高亮 yank 区域
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup,
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})
```

- [ ] **Step 2：验证**

```bash
nvim --headless "+lua print(vim.api.nvim_get_autocmds({ group = 'userconfig' })[1].pattern)" "+qa" 2>&1
```

预期：输出 `text`。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/autocmds.lua
git commit -m "feat(nvim): port autocmds from .vimrc"
```

---

## Task 5：插件 — 配色（tokyonight）

**Files:**
- Create: `config/nvim/lua/plugins/colorscheme.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,  -- 必须最先加载
    opts = { style = 'night' },
    config = function(_, opts)
      require('tokyonight').setup(opts)
      vim.cmd.colorscheme('tokyonight')
    end,
  },
}
```

- [ ] **Step 2：触发 lazy 安装**

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -10
```

预期：tokyonight clone 成功，无报错。

- [ ] **Step 3：验证**

```bash
nvim --headless "+lua print(vim.g.colors_name)" "+qa" 2>&1
```

预期：输出 `tokyonight-night`。

- [ ] **Step 4：commit**

```bash
git add config/nvim/lua/plugins/colorscheme.lua
git commit -m "feat(nvim): add tokyonight colorscheme"
```

---

## Task 6：插件 — Treesitter

**Files:**
- Create: `config/nvim/lua/plugins/treesitter.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'c', 'cpp', 'python', 'lua', 'bash',
        'markdown', 'markdown_inline',
        'json', 'yaml', 'toml', 'dockerfile',
        'vim', 'vimdoc', 'regex', 'gitcommit', 'diff',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = { 'BufReadPost', 'BufNewFile' },
  },
}
```

- [ ] **Step 2：安装 + 编译 parser**

```bash
nvim --headless "+Lazy! sync" "+TSUpdateSync" "+qa" 2>&1 | tail -20
```

预期：parser 编译完成（耗时 1-2 分钟，国内可能需要 proxychains）。

- [ ] **Step 3：验证 cpp parser 工作**

```bash
echo 'int main() { return 0; }' > /tmp/ts_test.cpp
nvim --headless /tmp/ts_test.cpp "+lua print(vim.treesitter.get_parser(0):lang())" "+qa" 2>&1
```

预期：输出 `cpp`。

- [ ] **Step 4：commit**

```bash
git add config/nvim/lua/plugins/treesitter.lua
git commit -m "feat(nvim): add treesitter with 16 parsers"
```

---

## Task 7：插件 — 补全（blink.cmp）

**Files:**
- Create: `config/nvim/lua/plugins/completion.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'saghen/blink.cmp',
    version = '*',  -- 用 release，不用 main
    event = 'InsertEnter',
    opts = {
      keymap = { preset = 'default' },
      appearance = {
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      signature = { enabled = true },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
    },
  },
}
```

- [ ] **Step 2：安装**

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -10
```

- [ ] **Step 3：验证 capability 接口**

```bash
nvim --headless "+lua print(type(require('blink.cmp').get_lsp_capabilities))" "+qa" 2>&1
```

预期：输出 `function`（lsp.lua 会用到这个）。

- [ ] **Step 4：commit**

```bash
git add config/nvim/lua/plugins/completion.lua
git commit -m "feat(nvim): add blink.cmp completion engine"
```

---

## Task 8：插件 — LSP（mason + lspconfig + 9 个 server）

**Files:**
- Create: `config/nvim/lua/plugins/lsp.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'b0o/SchemaStore.nvim',
      'saghen/blink.cmp',
    },
    config = function()
      require('mason-tool-installer').setup({
        ensure_installed = {
          -- LSP servers
          'clangd',
          'basedpyright',
          'lua-language-server',
          'bash-language-server',
          'marksman',
          'json-lsp',
          'yaml-language-server',
          'taplo',
          'dockerfile-language-server',
          'docker-compose-language-service',
          -- Formatters
          'clang-format',
          'ruff',
          'stylua',
          'shfmt',
          'prettier',
          -- Linters
          'shellcheck',
          'markdownlint',
          'yamllint',
          'hadolint',
          'cppcheck',
        },
        run_on_start = true,
      })

      local lspconfig = require('lspconfig')
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
        end
        map('gd', vim.lsp.buf.definition, 'goto definition')
        map('gD', vim.lsp.buf.declaration, 'goto declaration')
        map('gI', vim.lsp.buf.implementation, 'goto implementation')
        map('gr', function() require('telescope.builtin').lsp_references() end, 'references')
        map('K', vim.lsp.buf.hover, 'hover docs')
        map('<leader>D', vim.lsp.buf.type_definition, 'type definition')
        map('<leader>rn', vim.lsp.buf.rename, 'rename')
        map('<leader>ca', vim.lsp.buf.code_action, 'code action')
        map('<leader>e', vim.diagnostic.open_float, 'show diagnostic')
        map(']d', function() vim.diagnostic.jump({ count = 1 }) end, 'next diagnostic')
        map('[d', function() vim.diagnostic.jump({ count = -1 }) end, 'prev diagnostic')

        -- 旧 leaderf 风格（基于 LSP 而不是 gtags）
        map('<leader>fr', function() require('telescope.builtin').lsp_references() end, 'references')
        map('<leader>fd', vim.lsp.buf.definition, 'definitions')
      end

      local servers = {
        clangd = {
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
            '--function-arg-placeholders=true',
          },
          init_options = {
            fallbackFlags = { '-std=c++20', '-Wall', '-Wextra' },
          },
        },
        basedpyright = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
              diagnostics = { globals = { 'vim' } },
            },
          },
        },
        bashls = {},
        marksman = {},
        jsonls = {
          settings = {
            json = {
              schemas = require('schemastore').json.schemas(),
              validate = { enable = true },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = '' },
              schemas = require('schemastore').yaml.schemas(),
            },
          },
        },
        taplo = {},
        dockerls = {},
        docker_compose_language_service = {},
      }

      for name, cfg in pairs(servers) do
        cfg.capabilities = capabilities
        cfg.on_attach = on_attach
        lspconfig[name].setup(cfg)
      end

      vim.diagnostic.config({
        virtual_text = { prefix = '●' },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = '✘',
            [vim.diagnostic.severity.WARN]  = '⚠',
            [vim.diagnostic.severity.INFO]  = '●',
            [vim.diagnostic.severity.HINT]  = '●',
          },
        },
        update_in_insert = false,
      })
    end,
  },
}
```

- [ ] **Step 2：安装 LSP 插件，等 mason 自动装工具**

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -10
nvim --headless "+MasonToolsInstall" "+sleep 90" "+qa" 2>&1 | tail -20
```

预期：mason 安装 9 个 LSP + 5 个格式化 + 5 个 linter，完成后 `~/.local/share/nvim/mason/bin/clangd` 等存在。

- [ ] **Step 3：验证**

```bash
ls ~/.local/share/nvim/mason/bin/ | grep -E 'clangd|basedpyright|lua-language-server|bash-language-server|marksman|vscode-json-language-server|yaml-language-server|taplo|docker-langserver'
```

预期：每个工具至少出现一次。

```bash
echo 'int main() { return 0; }' > /tmp/lsp_test.cpp
nvim --headless /tmp/lsp_test.cpp "+sleep 3" "+lua print(#vim.lsp.get_clients({ bufnr = 0 }))" "+qa" 2>&1
```

预期：输出 `1` 或更多（clangd 已挂上）。

- [ ] **Step 4：commit**

```bash
git add config/nvim/lua/plugins/lsp.lua
git commit -m "feat(nvim): add LSP via mason for 9 languages"
```

---

## Task 9：插件 — Telescope（替代 LeaderF）

**Files:**
- Create: `config/nvim/lua/plugins/telescope.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    cmd = 'Telescope',
    keys = {
      -- 旧 LeaderF 键位完全移植
      { '<C-p>', function() require('telescope.builtin').find_files() end, desc = 'find files' },
      { '<C-b>', function() require('telescope.builtin').oldfiles() end, desc = 'recent files' },
      { '<C-f>', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'doc symbols' },
      { '<C-n>', function() require('telescope.builtin').lsp_workspace_symbols() end, desc = 'workspace symbols' },
      { '<leader>rg', function() require('telescope.builtin').live_grep() end, desc = 'live grep' },
      { '<leader>ft', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'doc symbols' },
      { '<leader>fo', function() require('telescope.builtin').resume() end, desc = 'resume last picker' },
      { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = 'buffers' },
    },
    config = function()
      require('telescope').setup({
        defaults = {
          layout_strategy = 'horizontal',
          layout_config = { height = 0.30, prompt_position = 'top' },
          sorting_strategy = 'ascending',
          path_display = { 'truncate' },
        },
      })
      pcall(require('telescope').load_extension, 'fzf')

      -- <leader>fn / <leader>fp：在 quickfix 里翻
      -- 用法：先 <leader>fr（lsp_references 默认进 quickfix），然后 fn/fp 翻
      vim.keymap.set('n', '<leader>fn', ':cnext<CR>', { silent = true, desc = 'next quickfix' })
      vim.keymap.set('n', '<leader>fp', ':cprev<CR>', { silent = true, desc = 'prev quickfix' })
    end,
  },
}
```

- [ ] **Step 2：安装**

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -10
```

- [ ] **Step 3：验证**

```bash
nvim --headless "+lua require('telescope.builtin').find_files; print('OK')" "+qa" 2>&1
```

预期：输出 `OK`。

- [ ] **Step 4：commit**

```bash
git add config/nvim/lua/plugins/telescope.lua
git commit -m "feat(nvim): add telescope with full LeaderF keymap parity"
```

---

## Task 10：插件 — Gitsigns（替代 vim-signify）

**Files:**
- Create: `config/nvim/lua/plugins/gitsigns.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add          = { text = '+' },
        change       = { text = '~' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end
        -- 旧 vimrc：<leader>diff = SignifyDiff
        map('<leader>diff', gs.diffthis, 'git diff')
        map(']c', function() gs.nav_hunk('next') end, 'next hunk')
        map('[c', function() gs.nav_hunk('prev') end, 'prev hunk')
        map('<leader>hp', gs.preview_hunk, 'preview hunk')
        map('<leader>hr', gs.reset_hunk, 'reset hunk')
        map('<leader>hb', function() gs.blame_line({ full = true }) end, 'blame line')
      end,
    },
  },
}
```

- [ ] **Step 2：安装 + 验证**

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -5
nvim --headless config/.zshrc "+sleep 1" "+lua print(vim.b.gitsigns_status_dict and 'OK' or 'NO_DICT')" "+qa" 2>&1
```

预期：输出 `OK`（如果 .zshrc 在 git 跟踪下）。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/plugins/gitsigns.lua
git commit -m "feat(nvim): add gitsigns replacing vim-signify"
```

---

## Task 11：插件 — Lualine（替代 vim-airline）

**Files:**
- Create: `config/nvim/lua/plugins/lualine.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        theme = 'tokyonight',
        globalstatus = true,
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
      tabline = {
        lualine_a = { 'buffers' },
        lualine_z = { 'tabs' },
      },
    },
  },
}
```

- [ ] **Step 2：安装 + 验证**

```bash
nvim --headless "+Lazy! sync" "+lua print(require('lualine').get_config().options.theme)" "+qa" 2>&1
```

预期：输出 `tokyonight`。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/plugins/lualine.lua
git commit -m "feat(nvim): add lualine replacing vim-airline"
```

---

## Task 12：插件 — Oil（替代 vim-dirvish）

**Files:**
- Create: `config/nvim/lua/plugins/oil.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'stevearc/oil.nvim',
    cmd = 'Oil',
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'open parent dir' },
    },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    -- 让 nvim path/to/dir 能直接打开 oil
    lazy = false,
    opts = {
      view_options = { show_hidden = true },
      keymaps = {
        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['<C-s>'] = 'actions.select_split',
        ['<C-v>'] = 'actions.select_vsplit',
        ['-'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
      },
    },
  },
}
```

- [ ] **Step 2：安装 + 验证**

```bash
nvim --headless "+Lazy! sync" "+lua require('oil'); print('OK')" "+qa" 2>&1
```

预期：输出 `OK`。

- [ ] **Step 3：交互验证（人工）**

```bash
nvim .
# 预期：直接进入 oil 视图列出当前目录
# 按 - 切换到父目录，按 q 退出
```

- [ ] **Step 4：commit**

```bash
git add config/nvim/lua/plugins/oil.lua
git commit -m "feat(nvim): add oil.nvim replacing vim-dirvish"
```

---

## Task 13：插件 — Autopairs

**Files:**
- Create: `config/nvim/lua/plugins/autopairs.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {
      check_ts = true,  -- 用 treesitter 判断上下文，避免在字符串/注释里乱配对
    },
  },
}
```

- [ ] **Step 2：安装 + 验证**

```bash
nvim --headless "+Lazy! sync" "+lua require('nvim-autopairs'); print('OK')" "+qa" 2>&1
```

预期：输出 `OK`。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/plugins/autopairs.lua
git commit -m "feat(nvim): add nvim-autopairs replacing auto-pairs"
```

---

## Task 14：插件 — Conform（格式化，含 F2 + 自动格式化策略）

**Files:**
- Create: `config/nvim/lua/plugins/conform.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      -- 旧 vimrc：<F2>(visual) = ClangFormat（现在覆盖到所有语言）
      {
        '<F2>',
        mode = { 'v', 'x' },
        function() require('conform').format({ async = false, lsp_fallback = true }) end,
        desc = 'format selection',
      },
      {
        '<F2>',
        mode = 'n',
        function() require('conform').format({ async = false, lsp_fallback = true }) end,
        desc = 'format buffer',
      },
    },
    init = function()
      vim.g.disable_autoformat = false
      vim.api.nvim_create_user_command('FormatToggle', function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        print('autoformat ' .. (vim.g.disable_autoformat and 'OFF' or 'ON'))
      end, { desc = 'toggle autoformat-on-save' })
      vim.keymap.set('n', '<leader>uf', '<cmd>FormatToggle<cr>', { desc = 'toggle autoformat' })
    end,
    opts = {
      formatters_by_ft = {
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        python = { 'ruff_format' },
        lua = { 'stylua' },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        markdown = { 'prettier' },
        json = { 'prettier' },
        yaml = { 'prettier' },
        toml = { 'taplo' },
      },
      formatters = {
        ['clang-format'] = {
          -- 旧 vimrc 的 Google + 4 个覆盖
          prepend_args = {
            '--style={BasedOnStyle: Google, DerivePointerAlignment: false, PointerAlignment: Left, AllowShortFunctionsOnASingleLine: Empty}',
          },
        },
        shfmt = {
          prepend_args = { '-i', '2', '-ci' },
        },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat then return false end
        -- 旧 vimrc：C/C++ 默认手动（g:clang_format#auto_format = 0）
        local ft = vim.bo[bufnr].filetype
        if ft == 'c' or ft == 'cpp' then return false end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
    },
  },
}
```

- [ ] **Step 2：安装 + 验证**

```bash
nvim --headless "+Lazy! sync" "+lua print(require('conform').list_formatters_to_run and 'OK' or 'NO')" "+qa" 2>&1
```

预期：输出 `OK`。

- [ ] **Step 3：实测格式化 lua 文件**

```bash
echo 'local x={a=1,b=2}' > /tmp/fmt_test.lua
nvim --headless /tmp/fmt_test.lua "+lua require('conform').format({ async = false })" "+w" "+qa" 2>&1
cat /tmp/fmt_test.lua
```

预期：被 stylua 重新排版，多空格与缩进正确。

- [ ] **Step 4：commit**

```bash
git add config/nvim/lua/plugins/conform.lua
git commit -m "feat(nvim): add conform.nvim with C/C++ manual format policy"
```

---

## Task 15：插件 — Lint（nvim-lint）

**Files:**
- Create: `config/nvim/lua/plugins/lint.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePost' },
    config = function()
      local lint = require('lint')
      lint.linters_by_ft = {
        python = { 'ruff' },
        sh = { 'shellcheck' },
        bash = { 'shellcheck' },
        markdown = { 'markdownlint' },
        yaml = { 'yamllint' },
        dockerfile = { 'hadolint' },
        cpp = { 'cppcheck' },
        c = { 'cppcheck' },
      }
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
        group = vim.api.nvim_create_augroup('userlint', { clear = true }),
        callback = function() require('lint').try_lint() end,
      })
    end,
  },
}
```

- [ ] **Step 2：安装 + 验证**

```bash
nvim --headless "+Lazy! sync" "+lua print(require('lint').linters_by_ft.dockerfile[1])" "+qa" 2>&1
```

预期：输出 `hadolint`。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/plugins/lint.lua
git commit -m "feat(nvim): add nvim-lint replacing ALE lint role"
```

---

## Task 16：插件 — Which-key

**Files:**
- Create: `config/nvim/lua/plugins/whichkey.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = { preset = 'modern' },
    keys = {
      { '<leader>?', function() require('which-key').show({ global = false }) end, desc = 'buffer keymaps' },
    },
  },
}
```

- [ ] **Step 2：安装 + 验证**

```bash
nvim --headless "+Lazy! sync" "+lua require('which-key'); print('OK')" "+qa" 2>&1
```

预期：输出 `OK`。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/plugins/whichkey.lua
git commit -m "feat(nvim): add which-key for keymap discovery"
```

---

## Task 17：插件 — Log Highlighting（保留旧的纯语法插件）

**Files:**
- Create: `config/nvim/lua/plugins/log-highlighting.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  { 'mtdl9/vim-log-highlighting', ft = 'log' },
}
```

- [ ] **Step 2：安装 + 验证**

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -5
```

预期：vim-log-highlighting clone 成功。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/plugins/log-highlighting.lua
git commit -m "feat(nvim): preserve vim-log-highlighting"
```

---

## Task 18：插件 — Avante（AI，空配置占位）

**Files:**
- Create: `config/nvim/lua/plugins/avante.lua`

- [ ] **Step 1：写 plugin 文件**

```lua
return {
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    version = false,
    build = 'make',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'stevearc/dressing.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    opts = {
      provider = 'claude',
      claude = {
        model = 'claude-sonnet-4-6',  -- 2026 年默认；可在 :help avante 查最新
      },
      -- 用法：export ANTHROPIC_API_KEY=sk-ant-... 后启动 nvim
      -- 不配 key 时 :checkhealth 会报"未配置"——预期行为，不影响其他功能
    },
  },
}
```

- [ ] **Step 2：安装**

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -10
```

预期：clone 完成；`make` 步骤需要 cargo（如未装可暂时忽略，等用户启用 AI 时再修）。

- [ ] **Step 3：commit**

```bash
git add config/nvim/lua/plugins/avante.lua
git commit -m "feat(nvim): add avante.nvim AI placeholder"
```

---

## Task 19：ftplugin — C++ ACM 模板

**Files:**
- Create: `config/nvim/ftplugin/cpp.lua`

- [ ] **Step 1：写 ftplugin**

```lua
-- 替代旧 acm_vimrc：F5 = 编译并运行（C++20）
vim.keymap.set('n', '<F5>', function()
  vim.cmd('write')
  local file = vim.fn.expand('%:p')
  local out = '/tmp/' .. vim.fn.expand('%:t:r')
  vim.cmd(string.format('!g++ -std=c++20 -O2 -Wall -o %s %s && %s', out, file, out))
end, { buffer = true, desc = 'compile and run C++' })
```

- [ ] **Step 2：验证**

```bash
echo '#include <bits/stdc++.h>
using namespace std;
int main() { cout << "hello acm\n"; return 0; }' > /tmp/acm_test.cpp
nvim --headless /tmp/acm_test.cpp "+lua print(vim.fn.maparg('<F5>', 'n', false, true).buffer)" "+qa" 2>&1
```

预期：输出 `1`（buffer-local 键位已绑定）。

- [ ] **Step 3：commit**

```bash
git add config/nvim/ftplugin/cpp.lua
git commit -m "feat(nvim): port acm_vimrc F5 to ftplugin/cpp.lua with C++20"
```

---

## Task 20：ftplugin — C

**Files:**
- Create: `config/nvim/ftplugin/c.lua`

- [ ] **Step 1：写 ftplugin**

```lua
vim.keymap.set('n', '<F5>', function()
  vim.cmd('write')
  local file = vim.fn.expand('%:p')
  local out = '/tmp/' .. vim.fn.expand('%:t:r')
  vim.cmd(string.format('!gcc -std=c11 -O2 -Wall -o %s %s && %s', out, file, out))
end, { buffer = true, desc = 'compile and run C' })
```

- [ ] **Step 2：commit**

```bash
git add config/nvim/ftplugin/c.lua
git commit -m "feat(nvim): add C ftplugin with F5 compile-and-run"
```

---

## Task 21：删除旧 ACM/YCM 文件

**Files:**
- Delete: `config/.ycm_extra_conf.py`
- Delete: `config/acm_vimrc`

- [ ] **Step 1：确认这两个文件确实没有被其他配置引用**

```bash
grep -rn 'ycm_extra_conf' config/ 2>/dev/null || echo "no refs"
grep -rn 'acm_vimrc' config/ 2>/dev/null || echo "no refs"
```

预期：`.vimrc` 里可能有 YCM 注释残留——这些是注释，删 ycm conf 不影响 vim 启动。

- [ ] **Step 2：删除**

```bash
git rm config/.ycm_extra_conf.py config/acm_vimrc
```

- [ ] **Step 3：commit**

```bash
git commit -m "chore: remove obsolete ycm_extra_conf and acm_vimrc

Behavior preserved:
- ACM F5 compile-and-run → config/nvim/ftplugin/cpp.lua (now C++20)
- C++ LSP → clangd via mason (uses compile_commands.json + fallback flags)"
```

---

## Task 22：端到端验证

- [ ] **Step 1：从干净状态完整跑一次 lazy sync**

```bash
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -20
```

预期：所有插件 sync 完成，无 ERROR。

- [ ] **Step 2：mason 工具完整安装**

```bash
nvim --headless "+MasonToolsInstall" "+sleep 120" "+qa" 2>&1 | tail -5
ls ~/.local/share/nvim/mason/bin/ | wc -l
```

预期：≥ 18（9 LSP + 5 formatter + 5 linter，部分二进制可能合并）。

- [ ] **Step 3：checkhealth**

```bash
nvim --headless "+checkhealth" +"write! /tmp/checkhealth.log" +qa
grep -E 'ERROR|✗' /tmp/checkhealth.log | grep -v 'avante' | head -20
```

预期：除 avante（未配 API key，预期）外无 ERROR。

- [ ] **Step 4：在测试 cpp 文件中检查 LSP 挂载 + F5**

```bash
echo '#include <iostream>
int main() { std::cout << "hi\n"; }' > /tmp/e2e.cpp
nvim --headless /tmp/e2e.cpp "+sleep 5" "+lua print('clients:', #vim.lsp.get_clients({ bufnr = 0 }))" "+lua print('F5:', vim.fn.maparg('<F5>', 'n', false, true).buffer)" "+qa" 2>&1
```

预期：`clients: 1`、`F5: 1`。

- [ ] **Step 5：在 Dockerfile 上检查 LSP + lint**

```bash
echo 'FROM ubuntu:22.04
RUN apt-get update' > /tmp/Dockerfile
nvim --headless /tmp/Dockerfile "+sleep 3" "+lua print('clients:', #vim.lsp.get_clients({ bufnr = 0 }))" "+qa" 2>&1
```

预期：`clients: 1`（dockerls 挂上）。

- [ ] **Step 6：启动时间**

```bash
nvim --startuptime /tmp/startup.log /tmp/e2e.cpp "+qa"
tail -1 /tmp/startup.log
```

预期：总耗时 < 200ms（首次因 mason 启动会更慢，第二次跑应稳定 < 100ms）。

- [ ] **Step 7：vim 兜底未坏**

```bash
vim --version | head -1
vim -e -c 'qa' 2>&1
```

预期：vim 仍能加载旧 `.vimrc` 退出（不进入交互）。

- [ ] **Step 8：交互冒烟（人工）**

打开一个 cpp 文件：
- 看 statusline 是 lualine（不是 airline）
- 按 `<C-p>` 弹 telescope find_files
- 按 `<leader>` 等 1 秒弹 which-key
- 按 `<F5>` 编译运行
- 按 `<C-J>` / `<C-K>` 切 tab
- 改一行触发 gitsigns 在行号列出现 `~`

如有任何键位异常，先排查并补 commit。

- [ ] **Step 9：写 README 节段（可选，小记一下）**

`config/README.MD` 追加：
```markdown

## Neovim 配置

`config/nvim/` 是 Neovim 配置（kickstart 派生，模块化 lua）。

安装：
\`\`\`bash
ln -sfT "$(pwd)/config/nvim" ~/.config/nvim
nvim   # 首次启动会自动装 lazy.nvim + mason 全套
\`\`\`

旧 `.vimrc` 保留作为 vim-only 环境的兜底。
```

- [ ] **Step 10：最终 commit**

```bash
git add config/README.MD
git commit -m "docs(nvim): add migration usage to README"
```

---

## Self-Review 检查结果

**1. Spec 覆盖**：
- ✅ A 方案（repo + 软链）→ Task 1 Step 4
- ✅ kickstart 派生 → 整体结构
- ✅ 删除 .vimrc 不动 → Task 21 仅删 ycm/acm，不动 .vimrc
- ✅ 删除 .ycm_extra_conf.py + acm_vimrc → Task 21
- ✅ ftplugin 接管 acm → Task 19
- ✅ tokyonight → Task 5
- ✅ avante 占位 → Task 18
- ✅ neovide → 系统侧依赖（spec §7），不在 nvim 配置内，本计划不强行装
- ✅ C++ 关闭自动格式化 → Task 14 format_on_save 显式排除
- ✅ 9 个 LSP + 工具链 → Task 8
- ✅ 旧键位 100% 保留 → Task 3 + Task 9 + Task 10 + Task 14 + Task 19
- ✅ gtags → LSP → Task 8 on_attach 中 `<leader>fr/fd`
- ✅ ALE → nvim-lint + LSP 拆分 → Task 8 + Task 15
- ✅ 双环境共存 → Task 22 Step 7

**2. Placeholder 扫描**：每个 step 都有具体代码或具体命令，无 TBD/TODO。

**3. 类型一致性**：`<leader>fr` 在 Task 8 和 Task 9 都定义了——这是有意的（LSP attach 时和无 buffer 时分别可用）；优先级上 buffer-local 会覆盖 global，行为一致。其余键位无重复定义冲突。

---

## 已知小风险（非 plan blocker）

1. **avante.nvim build = make** 需要 cargo——如果系统没装 cargo，Task 18 这步会有 build 错。降级方案：先 `lazy = true` 不 build，等用户后续 `pacman -S rust` 再 enable。本计划暂保持原样，因为 avante 的"装不上"不影响其他功能。
2. **国内 GitHub clone 速度**：Task 5/6/8 的 lazy sync 可能慢，必要时 `proxychains nvim --headless ...`。
3. **mason 镜像**：默认走 npm/pip/github，国内速度可能慢；mason 提供国内镜像配置但需另行设置——超出本次范围。

---

**计划完成 ✅**

---

## 会话进度笔记（2026-04-28，下次接续用）

### 已完成

| Task | 状态 | Commit |
|---|---|---|
| 1. bootstrap init.lua + lazy.nvim | ✅ 完整 | `b39be55` |
| 2. options.lua | ✅ 完整 | `035832b` |
| 3. keymaps.lua | ✅ 完整 | `04325b6` |
| 4. autocmds.lua | ✅ 完整 | `4efc992` |
| 5. tokyonight | ✅ 完整 | `f483071` |
| 6. treesitter | ✅ 完整（pinned to `branch='master'` 兼容 nvim 0.10） | `54844fa` |
| 7. blink.cmp | ✅ 完整 | `2291499` |
| 8. LSP | ⚠️ **文件已写、mason install 未跑** | `c48d467` |

### 下次开工的接续点

**先确认 lsp.lua 的内容**没有问题，然后从 **Task 8 的 Step 3** 开始：

```bash
# Step 3：mason 装 20 个工具（耗时 5-10 分钟）
timeout 600 nvim --headless "+MasonToolsInstall" "+sleep 480" "+qa" 2>&1 | tail -10
# 如果还有缺失再跑一遍（mason 幂等）

# Step 4：验证 mason 二进制
ls ~/.local/share/nvim/mason/bin/ 2>/dev/null

# Step 5：验证 clangd 挂上 buffer
echo 'int main() { return 0; }' > /tmp/lsp_test.cpp
nvim --headless /tmp/lsp_test.cpp "+sleep 8" "+lua print(#vim.lsp.get_clients({ bufnr = 0 }))" "+qa" 2>&1
# 期望输出: 1
```

如 Step 5 输出 0：检查 `~/.local/share/nvim/mason/bin/clangd` 是否存在。如果 `lspconfig[name].setup` 对某些 server 报 "no such server"——已经在 lsp.lua 里加了 pcall 兜底，不会阻塞，只会 warn。

### 待做（Task 9–22）

- 9 telescope（替代 LeaderF，键位 `<C-p>` 等）
- 10 gitsigns
- 11 lualine
- 12 oil.nvim
- 13 autopairs
- 14 conform（含 `<F2>` 格式化）
- 15 nvim-lint
- 16 which-key
- 17 log-highlighting
- 18 avante.nvim
- 19 ftplugin/cpp.lua（ACM `<F5>`）
- 20 ftplugin/c.lua
- 21 删除 `.ycm_extra_conf.py` + `acm_vimrc`
- 22 端到端验证 + README 更新

每个任务的完整 lua 代码已经在前文（Tasks 9–22 章节）。

### 风险提醒

- **国内网络**：lazy sync / mason install 走 GitHub/npm/pip，必要时 `proxychains nvim ...`
- **avante.nvim build = make**：需要 cargo（Rust）才能编译 tree-sitter wrapper。如系统没装 rust，Task 18 这步可能 build 失败但**不影响其他功能**（avante 装不上不会让 nvim 启动失败）
- **mason 国内镜像**：默认走原生源，如太慢可后续配置 `mason.providers`，超出本计划范围

### Git 状态（2026-04-28 收尾时）

- 分支：`nvim-migration`（基于 master，含 Task 1-8 共 8 个 feature commit + 2 个 docs commit = 10 commits ahead of origin/master）
- 远端：`https://github.com/111qqz/config.git`
- PR：见 GitHub

