-- 选最新可用的 g++（系统默认 g++ 在 Ubuntu 20.04 是 9.x，不支持 -std=c++20）
local function pick_cxx()
  for _, c in ipairs({ 'g++-13', 'g++-12', 'g++-11', 'g++-10', 'g++' }) do
    if vim.fn.executable(c) == 1 then return c end
  end
  return 'g++'
end

vim.keymap.set('n', '<F5>', function()
  vim.cmd('write')
  local file = vim.fn.expand('%:p')
  local out = '/tmp/' .. vim.fn.expand('%:t:r')
  vim.cmd(string.format('!%s -std=c++20 -O2 -Wall -o %s %s && %s', pick_cxx(), out, file, out))
end, { buffer = true, desc = 'compile and run C++' })
