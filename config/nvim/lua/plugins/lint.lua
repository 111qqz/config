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
        callback = function()
          local linters = lint.linters_by_ft[vim.bo.filetype]
          if not linters then return end
          -- 过滤本机上没装的二进制；nvim-lint 不会自动跳过
          local available = vim.tbl_filter(function(name)
            local def = lint.linters[name]
            local cmd = type(def) == 'table' and def.cmd or name
            cmd = type(cmd) == 'function' and cmd() or cmd
            return vim.fn.executable(cmd) == 1
          end, linters)
          if #available > 0 then lint.try_lint(available) end
        end,
      })
    end,
  },
}
