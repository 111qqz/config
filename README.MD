# 111qqz 的 dotfiles

本仓库是个人开发环境的统一配置，覆盖 vim/nvim、zsh、tmux、sway 桌面环境、proxychains，以及一份 Manjaro 一键装机脚本。

设计目标：
- **桌面主力机**（Manjaro / Arch）跑全套：sway + waybar + zsh-zinit + nvim + tmux
- **远程开发机 / 服务器 / 容器**：只跑 zsh + tmux + nvim 或 vim 兜底
- **极简兜底环境**（裸 ssh、生产容器）：只放一份 `.vimrc`，vim 9.0 即可工作

## 目录速览

```
.
├── .vimrc                   vim 兜底配置（vim-plug 管理插件）
├── config/nvim/             Neovim 主力配置（lua + lazy.nvim 模块化）
├── .zshrc                   zsh 主配置（zinit + powerlevel10k + oh-my-zsh）
├── .p10k.zsh                powerlevel10k 提示符配置（导出自 p10k configure）
├── .oh-my-zsh/              oh-my-zsh 自定义（zsh 兼容层，与 zinit 共存）
├── fish_tmux.conf           tmux 配置（文件名是历史遗留，不是 fish shell）
├── swaywm/sway/             sway 窗口管理器配置
├── swaywm/waybar/           waybar 状态栏 + style.css
├── proxychains.conf         本机 socks5://127.0.0.1:1080 代理链
├── install_manjaro.sh       Manjaro 一键装机脚本（pacman 装包 + 写 conf）
├── docs/superpowers/        nvim 迁移的 spec / plan（开发文档）
├── AGENTS.md                给 AI 助手的项目指引
└── README.MD                本文件
```

## 不同系统的装法

### Manjaro / Arch（桌面主力，推荐）

```bash
git clone https://github.com/111qqz/config.git ~/workspace/config
cd ~/workspace/config

# 1. 一键装系统包（注意：脚本会改 /etc/pacman.conf，先看一遍再跑）
sudo bash install_manjaro.sh

# 2. shell 配置
cp .zshrc ~/.zshrc
cp .p10k.zsh ~/.p10k.zsh
cp -r .oh-my-zsh ~/.oh-my-zsh    # 如果还没装 oh-my-zsh

# 3. tmux
cp fish_tmux.conf ~/.tmux.conf

# 4. sway 桌面
mkdir -p ~/.config/sway ~/.config/waybar
cp -r swaywm/sway/* ~/.config/sway/
cp -r swaywm/waybar/* ~/.config/waybar/

# 5. nvim 主力（软链，方便后续 git pull 直接生效）
ln -sfT "$(pwd)/config/nvim" ~/.config/nvim

# 6. proxychains（如果要走梯子）
sudo cp proxychains.conf /etc/proxychains.conf

# 7. 第一次启动 nvim：自动装 lazy.nvim + 拉所有插件 + mason 装 LSP/formatter
nvim
# 等约 1-2 分钟，所有 plugin 装完退出再开就秒开
```

### Ubuntu 20.04 / 22.04（远程开发机）

```bash
git clone https://github.com/111qqz/config.git ~/workspace/config
cd ~/workspace/config

# 1. shell（zsh + tmux）
cp .zshrc ~/.zshrc
cp .p10k.zsh ~/.p10k.zsh
cp -r .oh-my-zsh ~/.oh-my-zsh
cp fish_tmux.conf ~/.tmux.conf

# 2. nvim 配置（前提：本机已装 nvim ≥ 0.10）
ln -sfT "$(pwd)/config/nvim" ~/.config/nvim
nvim   # 首次启动自动装插件
```

**Ubuntu 20.04 已知约束**（Ubuntu 22.04+ 没这些问题）：
- 系统 glibc 2.31。Neovim 0.11+ 的 prebuilt 二进制要 2.34，装不上 → 保持 nvim 0.10.x
- 同样原因，mason 的 `stylua`（Rust 二进制）跑不起来 → 已从 conform 配置里移除 lua 自动格式化
- 系统默认 `g++` 9.4 不识别 `-std=c++20`。`config/nvim/ftplugin/cpp.lua` 已自动 fallback 到 `g++-13/12/11/10`，确保系统装了其中之一即可（`apt install g++-13`）
- 国内 PyPI 走 https 经常 TLS EOF。如果首次 `nvim` 时 mason 报 PyPI 失败，备选方案：用阿里云镜像装 Python LSP 到 `~/.local/bin/`：
  ```bash
  pip install --user --index-url https://mirrors.aliyun.com/pypi/simple/ \
    --trusted-host mirrors.aliyun.com basedpyright yamllint
  ```

### 容器 / 远程裸机（极简兜底）

只用 `.vimrc`：

```bash
# 容器内 root，或 ssh 到只能 vim 9 的机器：
curl -fsSL https://raw.githubusercontent.com/111qqz/config/master/.vimrc -o ~/.vimrc

# 第一次启动 vim 装 vim-plug，再 :PlugInstall
vim +PlugInstall +qa
```

`.vimrc` 与 `config/nvim/` 互不干扰：在桌面机上两份共存，`vim` 走老配置，`nvim` 走新配置。

## 各组件能干什么

### Neovim（主力）

`config/nvim/` 是 kickstart.nvim 派生的模块化 lua 配置：
- **LSP**：clangd / basedpyright / lua-ls / bashls / marksman / json-lsp / yaml-language-server / taplo / dockerls / docker-compose 共 9 个，由 mason 自动装
- **格式化**：F2 触发 conform.nvim，覆盖 c/cpp（手动）/ python / sh / markdown / json / yaml / toml；C/C++ 用 google style + `int*` 指针靠左
- **lint**：保存时自动跑 ruff / shellcheck / hadolint / yamllint / markdownlint / cppcheck（缺哪个跳哪个）
- **模糊查找**：`<C-p>` 文件、`<leader>rg` 全文 grep、`<C-f>/<C-n>` 文档/工程符号
- **git**：gitsigns 在行号列显示增删改、`<leader>diff` 对比、`]c/[c` 跳转 hunk
- **AI**：avante.nvim 占位，`export ANTHROPIC_API_KEY=...` 后启用
- **C/C++ ACM**：`<F5>` 一键编译运行（自动选最新 g++/gcc）

完整键位看 `config/nvim/lua/keymaps.lua` 和各 `lua/plugins/*.lua`，或在 nvim 里按 `<leader>?` 弹 which-key。

### Vim（兜底）

`.vimrc` 用 vim-plug 装：vim-airline / LeaderF / vim-dirvish / vim-clang-format 等。功能比 nvim 弱，但在没 nvim 的环境（老 docker 镜像、生产机）能用。

### Zsh

zinit 加载 powerlevel10k 提示符 + autosuggestions + syntax-highlighting；同时 source `~/.oh-my-zsh` 拿一些常用 alias。

### Tmux

`fish_tmux.conf`（文件名历史遗留，与 fish shell 无关）：vi 模式、256 色、自动 new-session。

### Sway

Wayland 平铺式窗口管理器配置 + waybar 状态栏。仅适用于 Manjaro/Arch 桌面。

## 排错

| 现象 | 原因 / 处理 |
|---|---|
| `nvim` 第一次启动卡死 | lazy.nvim 在 clone GitHub 插件，国内可能慢；用 `proxychains nvim` 加速 |
| `:checkhealth` 报 `luarocks not installed` | 当前没插件依赖 rocks，是告知性 ERROR，可忽略 |
| `:write` cpp 文件报 cppcheck ENOENT | `apt install cppcheck` 或忽略（lint 已自动跳过缺失工具，但你可能从老 commit 拉的代码） |
| `<F5>` 报 `unrecognized -std=c++20` | 系统 g++ < 10。装一个新 g++：`apt install g++-13` |
| nvim 启动报 nvim-lspconfig deprecated 0.10 | 已知，不影响功能。等系统升级到 Ubuntu 22+ 后再升 nvim 0.11+ |
| mason 装 PyPI 包失败（SSL EOF） | 国内 TLS 干扰，改用阿里云镜像见上文 Ubuntu 章节 |
| stylua 跑不起来 / lua 不会自动格式化 | mason 二进制需要 glibc 2.34，Ubuntu 20.04 不支持。装 cargo + `cargo install stylua` 可恢复 |

## 给开发者：repo 约定

- **不在裸 master 上开发**：所有改动都先开 feature 分支 → PR → merge（详见 `AGENTS.md`）
- **共存原则**：动 `config/nvim/` 不动 `.vimrc`（反之亦然）
- **commit 信息约定**：`feat(nvim):` / `fix(nvim):` / `docs:` / `chore:` 风格
- **AI 协作约定**：见 `AGENTS.md`
