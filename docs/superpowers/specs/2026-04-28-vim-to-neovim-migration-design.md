# Vim → Neovim 迁移设计

**日期**：2026-04-28
**Repo**：`/home/renkz/workspace/config`
**前置背景**：详见 `/home/renkz/.claude/plans/2026-humming-meerkat.md`（dotfiles 现代化评估），本文档是其中 P2 项的实施设计。

---

## 1. Context（为什么做这件事）

`config/.vimrc` 是一份积累多年的 Vim 8 配置，技术栈停留在 2020 年前后：YouCompleteMe（已基本停维）+ ALE（同时承担补全/诊断/格式化三角色）+ LeaderF + gtags + vim-signify + airline + dirvish。配套 `.ycm_extra_conf.py` 硬编码 macOS framework 路径与 `-std=c++11`。这套体系在 2026 年的核心问题是：

- **YCM/ALE 双补全栈**已被 native LSP 全面取代，社区资源与插件生态都在向 Neovim + LSP 倾斜。
- **gtags 索引**已被 LSP 的语义查询取代（更准、不需要后台索引文件）。
- **vimscript 配置语言**性能与可读性都不如 Lua，且新插件越来越多只支持 Neovim。
- **GUI 选择 gvim** 在 Wayland 下体验落后 neovide（GPU 加速、动画顺滑）。

迁移目标：把日常编辑器升级到 2026 年的现代 Neovim 栈，**同时不破坏远程裸机 / 容器里只有 vim 的兜底使用场景**。

---

## 2. 核心决策（已与用户确认）

| 决策 | 选择 | 理由 |
|---|---|---|
| 起点 | **Kickstart 派生**（不用 LazyVim 发行版，也不完全从零） | 用户已有强烈个人键位偏好；LazyVim 默认会冲突；从零浪费时间 |
| 配置位置 | `config/nvim/`，软链到 `~/.config/nvim/` | A 方案：repo 内集中管理 |
| 旧 vim | **保留** `.vimrc` 与 vim-plug 体系 | 远程服务器/容器仍需 vim 兜底；旧 `.vimrc` 第 62 行已经同时支持 vim 和 nvim |
| `.ycm_extra_conf.py` | **删除** | clangd 用 `compile_commands.json`，单文件场景靠 fallback flags |
| `acm_vimrc` | **删除并合并**进 `nvim/ftplugin/cpp.lua` | 用 ftplugin 机制更干净；同时升 C++11 → C++20 |
| 配色 | tokyonight | 2026 主流，可读性高 |
| AI 补全 | avante.nvim（先装空配置） | Cursor 风格，可接 Claude/GPT；用户启用时再填 key |
| GUI | neovide | GPU 加速、Wayland 友好 |
| C++ 自动格式化 | **关闭**（保留 `<F2>` 手动） | 与旧 vimrc `g:clang_format#auto_format = 0` 一致；ACM 提交时不被改 |
| 其他语言自动格式化 | 保存时开启，`<leader>uf` 切换 |

---

## 3. 目录结构

```
config/nvim/
├── init.lua                  # 入口：基础选项 + 加载 lazy.nvim
├── lua/
│   ├── options.lua           # set 选项（nu/cursorline/ignorecase/smartcase/undofile/updatetime=100/signcolumn=yes/termguicolors 等）
│   ├── keymaps.lua           # 通用键位（C-J/C-K 切 tab、Tab/S-Tab 切 buffer、F4 高亮行尾、方向键阻止）
│   ├── autocmds.lua          # FileType=text 设 textwidth=78 等
│   └── plugins/              # lazy.nvim 自动收集，每文件一插件
│       ├── colorscheme.lua   # tokyonight
│       ├── lsp.lua           # mason + lspconfig + 8 类语言 server
│       ├── completion.lua    # blink.cmp
│       ├── treesitter.lua    # nvim-treesitter (16 个 parser)
│       ├── telescope.lua     # 替代 LeaderF，含 leader+f* 全套
│       ├── gitsigns.lua      # 替代 vim-signify
│       ├── lualine.lua       # 替代 vim-airline
│       ├── oil.lua           # 替代 vim-dirvish
│       ├── autopairs.lua     # 替代 jiangmiao/auto-pairs
│       ├── conform.lua       # 格式化（clang-format/ruff/stylua/shfmt/prettier/taplo）
│       ├── lint.lua          # nvim-lint（hadolint/yamllint/markdownlint/cppcheck/shellcheck）
│       ├── whichkey.lua      # 键位发现器
│       ├── log-highlighting.lua # 保留 mtdl9/vim-log-highlighting
│       └── avante.lua        # AI（空配置占位）
└── ftplugin/
    ├── cpp.lua               # F5 = g++ -std=c++20 -O2 -Wall -o /tmp/a && /tmp/a
    └── c.lua                 # 类似（C99）
```

**取舍说明**：
- 一文件一插件：未来加/删插件不必搜整个文件
- `ftplugin/` 是 nvim 原生机制，比 autocmd 写法更干净
- `lua/options.lua / keymaps.lua / autocmds.lua` 三文件完全是个人配置，不依赖任何插件，nvim 启动最早期加载

---

## 4. 插件替换映射

| 旧 (vim-plug) | 新 (lazy.nvim) | 备注 |
|---|---|---|
| `octol/vim-cpp-enhanced-highlight` | nvim-treesitter (cpp parser) | TS 语法高亮远超手写正则 |
| `justinmk/vim-dirvish` + `vim-dirvish-git` | `stevearc/oil.nvim` | dirvish 哲学的精神继承者 |
| `jiangmiao/auto-pairs` | `windwp/nvim-autopairs` | 与 blink.cmp 集成 |
| `vim-airline/vim-airline` + themes | `nvim-lualine/lualine.nvim` | tokyonight 主题适配 |
| `Yggdroot/LeaderF` | `nvim-telescope/telescope.nvim` + `telescope-fzf-native` | gtags 部分用 LSP references/definitions 替代 |
| `mhinz/vim-signify` | `lewis6991/gitsigns.nvim` | `<leader>diff` 保留 |
| `mtdl9/vim-log-highlighting` | 保留原样 | 纯语法文件，无替代品 |
| `rhysd/vim-clang-format` | `stevearc/conform.nvim` + clang-format | `<F2>` 键位 + Google + 4 项覆盖 |
| `rafi/awesome-vim-colorschemes` | 删除 | 仅保留 tokyonight |
| `fratajczak/one-monokai-vim` | 删除 | 同上 |
| ALE | `nvim-lint`（lint）+ `nvim-lspconfig`（诊断） | 角色拆分，避免重复诊断 |
| YCM + `.ycm_extra_conf.py` | `clangd` via lspconfig + 删除 ycm conf | ACM 单文件靠 fallback flags |

**新增（旧 vimrc 没有但 2026 必备）**：
- `lazy.nvim`：插件管理器
- `mason.nvim` + `mason-lspconfig` + `mason-tool-installer`：自动装 LSP/格式化/lint
- `blink.cmp`：补全引擎（2025 起明显比 nvim-cmp 快）
- `folke/which-key.nvim`：leader 键位提示
- `nvim-treesitter` + `textobjects`
- `yetone/avante.nvim`：AI（空配置）

---

## 5. 键位完全保留清单（与旧 vimrc 字面一致）

| 键 | 行为 | 实现 |
|---|---|---|
| `<F2>`（visual） | 格式化选区 | conform.nvim |
| `<F4>` | 高亮行尾空格 | autocmd 内重复实现 `:/\s\+$<CR>` |
| `<F5>`（cpp） | 编译并运行 | ftplugin/cpp.lua |
| `<C-p>` | 找文件 | telescope find_files |
| `<C-b>` | 最近文件 | telescope oldfiles |
| `<C-f>` | 当前文件符号 | telescope lsp_document_symbols |
| `<C-n>` | 工作区符号 | telescope lsp_workspace_symbols |
| `<C-J>` / `<C-K>` | 切 tab | `:tabp` / `:tabn` |
| `<Tab>` / `<S-Tab>` | 切 buffer（带自动保存） | bnext/bprev |
| `<leader>rg` | 全局搜索 | telescope live_grep |
| `<leader>ft` | 当前文件 tag | telescope lsp_document_symbols |
| `<leader>fr` | 引用 | LSP references |
| `<leader>fd` | 定义 | LSP definitions |
| `<leader>fn` / `<leader>fp` | 下一/上一引用（先按 `<leader>fr` 把结果送 quickfix，再用 fn/fp 翻） | `:cnext` / `:cprev` |
| `<leader>diff` | git diff | gitsigns diffthis |
| 方向键阻止训练（normal+insert） | 提示用 hjkl | 原 mapping 直接搬过来 |

**LSP `on_attach` 通用键位**（所有语言生效，新增）：

| 键 | 行为 |
|---|---|
| `gd` / `gD` / `gI` | 定义 / 声明 / 实现 |
| `gr` | 引用 |
| `K` | 悬浮文档 |
| `<leader>rn` | 重命名 |
| `<leader>ca` | code action |
| `<leader>e` | 浮窗看完整诊断 |
| `]d` / `[d` | 跳转下一个/上一个诊断 |

---

## 6. LSP / 格式化 / Lint 工具链（按语言）

| 语言 | LSP | 格式化 (conform) | Linter (nvim-lint) |
|---|---|---|---|
| C/C++ | clangd | clang-format（Google + 4 项覆盖） | cppcheck（按需） |
| Python | basedpyright | ruff_format | ruff |
| Lua | lua_ls | stylua | — |
| Shell | bashls | shfmt | shellcheck |
| Markdown | marksman | prettier | markdownlint |
| JSON | jsonls + schemastore | prettier | — |
| YAML | yamlls + schemastore | prettier | yamllint |
| TOML | taplo | taplo | — |
| Dockerfile | dockerls + docker-compose-language-service | — | hadolint |

**clangd 启动参数**：
```
--background-index --clang-tidy --header-insertion=iwyu
--completion-style=detailed --function-arg-placeholders=true
```
**Fallback flags**（无 `compile_commands.json` 时）：`-std=c++20 -Wall -Wextra`

**Treesitter 安装语言**：
`c, cpp, python, lua, bash, markdown, markdown_inline, json, yaml, toml, dockerfile, vim, vimdoc, regex, gitcommit, diff`

---

## 7. 系统侧依赖（pacman 装）

```
neovim          # >= 0.10（Arch 当前 0.11+ ✅）
neovide         # GUI 前端
ripgrep         # telescope live_grep 依赖
fd              # telescope find_files 加速
git curl unzip  # mason 下载
gcc             # treesitter 编译 parser
nodejs npm      # node 实现的 LSP（basedpyright/bashls/marksman/dockerls 等）
```

其他工具（clangd、stylua、shfmt、ruff、prettier 等）**全部由 mason 接管**，安装到 `~/.local/share/nvim/mason/`，**不需要 pacman**。

`install_manjaro.sh` 同时追加：
```bash
ln -sfT "$REPO/nvim" "$HOME/.config/nvim"
```

---

## 8. 自动安装链路（用户首次 `nvim`）

1. `init.lua` 检测 `~/.local/share/nvim/lazy/lazy.nvim` 不存在 → 自动 `git clone`
2. `lazy.nvim` 启动 → 读取 `lua/plugins/*.lua` → 全部插件并行 clone（≤30s）
3. `mason-tool-installer` 启动 → 下载 9 个 LSP（clangd、basedpyright、lua_ls、bashls、marksman、jsonls、yamlls、taplo、dockerls）+ 格式化/lint 工具到 `~/.local/share/nvim/mason/`
4. Treesitter 自动编译 16 种 parser
5. 完成。后续启动 ~50ms（lazy load）

---

## 9. 双环境共存验证

| 环境 | 命令 | 配置 |
|---|---|---|
| Manjaro 主机 | `nvim` | `~/.config/nvim` → `config/nvim/`（新） |
| Manjaro 主机 | `vim` | `~/.vimrc`（旧，原样保留） |
| 远程 vim-only 服务器 | `vim` | 需先 `vim +PlugInstall` 装一次插件（与现状一致） |
| 任何机器装 nvim 但没新配置 | `nvim -u ~/.vimrc` | 旧 vimrc L62 已支持 nvim 的 stdpath 分支 |

**两套 plugin 目录互不污染**：`~/.vim/plugged/` (vim-plug) ↔ `~/.local/share/nvim/lazy/` (lazy.nvim)

---

## 10. 验证清单（实施后必跑）

- [ ] `nvim --version` ≥ 0.10
- [ ] `nvim --headless "+Lazy! sync" +qa` 退出码 0
- [ ] `nvim --headless "+MasonToolsInstall" "+sleep 60" +qa` 全部工具 ✅
- [ ] `:checkhealth` 中 `lazy/mason/lspconfig/treesitter` 全 OK
- [ ] 打开 `acm_vimrc.cpp` 测试样本：clangd 起 → 补全 → `<F5>` 编译运行
- [ ] 打开 `install_manjaro.sh`：bashls 起 + shellcheck 给出 lint
- [ ] 打开任意 Dockerfile：dockerls + hadolint 同时工作
- [ ] `:Telescope find_files` + `<C-p>` 工作
- [ ] `:Gitsigns toggle_signs` 改过的文件可见 `+/~/-`
- [ ] `:Oil` 可编辑式打开当前目录
- [ ] `vim` 命令仍能加载旧 `.vimrc` 不报错
- [ ] `nvim --startuptime /tmp/start.log /tmp/x.cpp` < 100ms

---

## 11. 风险与已知限制

1. **avante.nvim** 需 API key，首次 `:checkhealth` 会报"未配置"——不影响其他功能
2. **clangd 无 `compile_commands.json`** 时对系统头偶尔报红——预期行为；工程用 `bear -- make` 或 `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON` 生成
3. **首次 `:Lazy sync` 网络敏感**（国内 GitHub）——首装可用 `proxychains nvim`
4. **旧 `~/.vim/plugged/`** 留着——不影响 nvim，清理放进未来 P3 阶段
5. **mason 包列表**会被快照在 lazy-lock.json，跨机迁移把 `~/.local/share/nvim/` 删掉重跑 nvim 会自动还原

---

## 12. 后续步骤（不在本次范围）

- 在 `install_manjaro.sh` 中加入上述系统依赖（属于 P0 整改的一部分，本次先不动该脚本，等 P0 一起处理）
- AI key 配置（用户自行）
- 删除旧 `~/.vim/plugged/`（P3 清理）
- 把 `.vimrc` 也精简（P3）

---

## 13. 待动文件清单（实施阶段）

**新增**：
- `config/nvim/init.lua`
- `config/nvim/lua/options.lua`
- `config/nvim/lua/keymaps.lua`
- `config/nvim/lua/autocmds.lua`
- `config/nvim/lua/plugins/{colorscheme,lsp,completion,treesitter,telescope,gitsigns,lualine,oil,autopairs,conform,lint,whichkey,log-highlighting,avante}.lua`
- `config/nvim/ftplugin/cpp.lua`
- `config/nvim/ftplugin/c.lua`

**删除**：
- `config/.ycm_extra_conf.py`
- `config/acm_vimrc`（内容并入 `ftplugin/cpp.lua`）

**保留不动**：
- `config/.vimrc`
- `config/.zshrc`、`config/.p10k.zsh`、`config/fish_tmux.conf`、`config/install_manjaro.sh`、`config/proxychains.conf`、`config/swaywm/*`（其他文件 P0/P1/P3 处理）
