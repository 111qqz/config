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
