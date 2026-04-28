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
