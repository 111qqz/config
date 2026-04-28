local function pick_cc()
  for _, c in ipairs({ 'gcc-13', 'gcc-12', 'gcc-11', 'gcc-10', 'gcc' }) do
    if vim.fn.executable(c) == 1 then return c end
  end
  return 'gcc'
end

vim.keymap.set('n', '<F5>', function()
  vim.cmd('write')
  local file = vim.fn.expand('%:p')
  local out = '/tmp/' .. vim.fn.expand('%:t:r')
  vim.cmd(string.format('!%s -std=c11 -O2 -Wall -o %s %s && %s', pick_cc(), out, file, out))
end, { buffer = true, desc = 'compile and run C' })
