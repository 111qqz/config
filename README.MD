## just some config files for 111qqz

## Neovim 配置

`config/nvim/` 是 Neovim 配置（kickstart 派生，模块化 lua）。

安装：
```bash
ln -sfT "$(pwd)/config/nvim" ~/.config/nvim
nvim   # 首次启动会自动装 lazy.nvim + mason 全套
```

旧 `.vimrc` 保留作为 vim-only 环境的兜底。
