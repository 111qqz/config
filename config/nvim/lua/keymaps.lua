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
