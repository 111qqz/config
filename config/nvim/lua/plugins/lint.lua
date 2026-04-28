return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePost' },
    config = function()
      local lint = require('lint')
      lint.linters_by_ft = {
        python = { 'ruff' },
        sh = { 'shellcheck' },
        bash = { 'shellcheck' },
        markdown = { 'markdownlint' },
        yaml = { 'yamllint' },
        dockerfile = { 'hadolint' },
        cpp = { 'cppcheck' },
        c = { 'cppcheck' },
      }
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost', 'InsertLeave' }, {
        group = vim.api.nvim_create_augroup('userlint', { clear = true }),
        callback = function() require('lint').try_lint() end,
      })
    end,
  },
}
