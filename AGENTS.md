# AGENTS.md — 给 AI 协作者的项目指引

本文件用 [agents.md](https://agents.md) 约定，被 Claude Code、Cursor、aider、Codex 等多家 AI 工具识别。

## 这是什么仓库

111qqz 的个人 dotfiles。**单 owner**，服务三类环境：

1. **Manjaro 桌面**（主力，软件最新）
2. **Ubuntu 20.04+ 服务器/远程机**（大量约束，见下）
3. **极简容器/裸 ssh**（只信任 `.vimrc` 兜底）

不要假设这是被多人维护的项目；不要建议添加 CI、issue templates、CONTRIBUTING.md 这类协作开销。

## 文件组织

```
.vimrc                       vim 兜底，老配置（vim-plug + LeaderF/airline 等）
config/nvim/                 Neovim 主力（kickstart 派生，模块化 lua）
├── init.lua                 leader 设置 → 加载 options/keymaps/autocmds → lazy.nvim
├── lua/options.lua          全局 vim.opt
├── lua/keymaps.lua          全局 keymap
├── lua/autocmds.lua         全局 autocmd
├── lua/plugins/<name>.lua   一文件一插件，lazy 加载
└── ftplugin/{c,cpp}.lua     buffer-local 配置（F5 编译运行等）
.zshrc / .p10k.zsh / .oh-my-zsh/    zsh 全套
fish_tmux.conf               tmux 配置（文件名是历史遗留）
swaywm/sway/                 sway WM
swaywm/waybar/               waybar 状态栏
proxychains.conf             socks5://127.0.0.1:1080
install_manjaro.sh           Manjaro 一键装机
docs/superpowers/            spec / plan 文档
```

## 关键约束（必读）

### 1. Ubuntu 20.04 = glibc 2.31，是事实硬限

宿主常驻 Ubuntu 20.04，glibc 2.31。**不要主动建议升级 nvim 到 0.11+**：prebuilt 二进制要 glibc 2.32-2.34，装不上。同样的限制波及：
- mason `stylua`（Rust 静态 + 新 glibc）→ 已从 conform 移除 lua 自动格式化
- 任何要 glibc ≥ 2.32 的 prebuilt 工具

如果你看到 `Neovim 0.10 or older is deprecated` 这条 lspconfig 警告，**这是已知非问题**，不要当 bug 处理。

**缺 glibc 时不要绕路**（不要源码编译、conda 装、AppImage extract、patchelf）：用户已明确"先算了，等 OS 升级再处理"。改用 PATH 上的系统包或跳过该工具即可。

### 2. PyPI 走墙不稳定

`pypi.org` 与 `pypi.tuna.tsinghua.edu.cn` 经常 TLS EOF（SSL 干扰）。mason 自带的 pip 装 Python 工具会失败。已知 workaround：阿里云镜像。

```bash
pip install --user --index-url https://mirrors.aliyun.com/pypi/simple/ \
  --trusted-host mirrors.aliyun.com <pkg>
```

不要再尝试代理（`HTTPS_PROXY=...`），代理不解决这个 TLS 干扰。

### 3. `~/.local/bin` 已有的工具优先于 mason

当前由系统 PATH 提供（不要重复让 mason 装）：
- `basedpyright`、`yamllint`：阿里云 pip 装
- `ruff`：用户自装
- `clang-format`：`/usr/bin/clang-format`（系统包）
- `cppcheck`：不在 mason registry，依赖系统 `apt install cppcheck`

`config/nvim/lua/plugins/lsp.lua` 的 `mason-tool-installer.ensure_installed` 不包含上述工具，**不要把它们加回去**。

### 4. C/C++ 编译用 g++-13

Ubuntu 20.04 默认 `g++` 是 9.4，不识别 `-std=c++20`。`config/nvim/ftplugin/cpp.lua` 的 `pick_cxx()` 已实现 fallback：`g++-13/12/11/10/g++` 顺序选第一个可执行的。要改 C++ 编译参数动这个文件，**不要**直接 hardcode `g++`。

### 5. nvim 与 vim 共存

`.vimrc` 是兜底，**不要动它**（除非用户明确要求）。所有现代化都进 `config/nvim/`。两套配置互不引用、互不依赖。

## 提交流程

1. **不在 master 上写新代码**：必要时开 feature 分支
   - 命名风格：`nvim-migration`、`nvim-post-merge-fixes`、`<topic>-<purpose>` 短横线
2. **commit 信息**：约定式 commit
   - `feat(nvim): xxx`、`fix(nvim): xxx`、`docs(...): xxx`、`chore: xxx`
   - 多行 body 写"为什么"，**不**写"做了什么"（diff 自己会说）
   - **不**写 "🤖 Generated with..." 之类的 footer
3. **PR**：`gh pr create --base master --head <branch>`
   - title 用同样的约定式格式，70 字符内
   - body 写 Summary + 已知偏离 + Test Plan
4. **合并**：`gh pr merge <num> --merge --delete-branch`
   - 用 merge commit（保留 commit 历史，不 squash）
5. **本地同步**：`git checkout master && git pull --ff-only && git fetch -p`

**不要主动 push**：committed 不等于 pushed。在用户说"提交 MR"或"push"之前，所有 commit 都留在本地。

## 修 nvim 配置的检查清单

改完任何 `config/nvim/lua/plugins/*.lua` 后必跑：

```bash
# 1. 装/同步插件
nvim --headless "+Lazy! sync" "+qa" 2>&1 | tail -10

# 2. checkhealth 没新 ERROR（除已知的 luarocks/avante）
nvim --headless "+checkhealth" "+write! /tmp/h.log" "+qa" 2>&1
grep -E 'ERROR|✗' /tmp/h.log | grep -vE 'avante|luarocks'

# 3. 关键功能：clangd 在 cpp 上挂得上
echo 'int main() { return 0; }' > /tmp/lsp.cpp
nvim --headless /tmp/lsp.cpp "+sleep 5" \
  "+lua print(#vim.lsp.get_clients({ bufnr = 0 }))" "+qa" 2>&1
# 期望: 1
```

改 LSP / mason 列表：动 `lsp.lua`，记得对 `mason-tool-installer.ensure_installed` 用与 mason registry 一致的 package 名（不是 lspconfig 名；如 `lua-language-server` 不是 `lua_ls`）。

改 conform 格式化策略：`format_on_save` 函数对 c/cpp 显式 `return false` 是**有意为之**（旧 `.vimrc` 行为：C/C++ 不自动格式化）。不要"为统一性"删掉。

改 nvim-lint 自动 lint：autocmd 里有 `vim.fn.executable` 过滤，**不要简化掉**——这是 cppcheck 缺失时不让 `:write` 报错的关键。

## 测试约定

nvim 配置没有传统单元测试。**验证 = headless 命令**。每条命令该返回什么，写在 `docs/superpowers/plans/2026-04-28-vim-to-neovim-migration.md` 的"验证步"里。

主流程：

```bash
# 模块单测
nvim --headless "+lua require('<module>'); print('OK')" "+qa" 2>&1

# 端到端（71 项测试的脚本散落在 /tmp/nvim_smoke.lua + /tmp/nvim_deep.lua，
# 上次跑全过；如果改了核心配置可以重新写一份）
```

不要**用 vim test 框架**或引入 `plenary` 的 `busted` 跑测试——单 owner 项目，过度抽象。

## 不要做的事

- 不要建议升级 nvim 到 0.11+（glibc 卡住）
- 不要给 `.vimrc` 加新插件（用户已迁移到 nvim）
- 不要给 conform 加 lua 自动格式化（stylua 装不上）
- 不要给 mason 加回 `basedpyright/ruff/yamllint/clang-format/cppcheck`
- 不要在 master 上直接开发；不要主动 `git push`
- 不要写 `// fixed bug X` / `// added per request Y` 的代码注释
- 不要为了"防御性"加用不到的 try/catch / pcall（lspconfig 的 `pcall` 是有意保留的，仅此一例）
- 不要在 commit message 加 emoji 或 AI 署名

## 仓库内更多上下文

- `docs/superpowers/specs/` — 设计 spec
- `docs/superpowers/plans/` — 实施计划（含每步验证命令）
- `git log` — 真实历史，每个 commit message 写了"为什么"

遇到不确定的问题先看 spec/plan，再看 commit message，最后才动手。
