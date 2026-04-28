return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<F2>',
        mode = { 'v', 'x' },
        function() require('conform').format({ async = false, lsp_fallback = true }) end,
        desc = 'format selection',
      },
      {
        '<F2>',
        mode = 'n',
        function() require('conform').format({ async = false, lsp_fallback = true }) end,
        desc = 'format buffer',
      },
    },
    init = function()
      vim.g.disable_autoformat = false
      vim.api.nvim_create_user_command('FormatToggle', function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        print('autoformat ' .. (vim.g.disable_autoformat and 'OFF' or 'ON'))
      end, { desc = 'toggle autoformat-on-save' })
      vim.keymap.set('n', '<leader>uf', '<cmd>FormatToggle<cr>', { desc = 'toggle autoformat' })
    end,
    opts = {
      formatters_by_ft = {
        c = { 'clang-format' },
        cpp = { 'clang-format' },
        python = { 'ruff_format' },
        -- lua: stylua mason 二进制需要 glibc 2.34（本机 2.31）；无 cargo
        -- 暂不配 lua 格式化（lua_ls 没有内置 formatter；如需则装系统 stylua）
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        markdown = { 'prettier' },
        json = { 'prettier' },
        yaml = { 'prettier' },
        toml = { 'taplo' },
      },
      formatters = {
        ['clang-format'] = {
          prepend_args = {
            '--style={BasedOnStyle: Google, DerivePointerAlignment: false, PointerAlignment: Left, AllowShortFunctionsOnASingleLine: Empty}',
          },
        },
        shfmt = {
          prepend_args = { '-i', '2', '-ci' },
        },
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat then return false end
        local ft = vim.bo[bufnr].filetype
        if ft == 'c' or ft == 'cpp' then return false end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
    },
  },
}
