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
