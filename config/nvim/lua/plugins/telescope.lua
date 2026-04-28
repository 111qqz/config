return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    cmd = 'Telescope',
    keys = {
      { '<C-p>', function() require('telescope.builtin').find_files() end, desc = 'find files' },
      { '<C-b>', function() require('telescope.builtin').oldfiles() end, desc = 'recent files' },
      { '<C-f>', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'doc symbols' },
      { '<C-n>', function() require('telescope.builtin').lsp_workspace_symbols() end, desc = 'workspace symbols' },
      { '<leader>rg', function() require('telescope.builtin').live_grep() end, desc = 'live grep' },
      { '<leader>ft', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'doc symbols' },
      { '<leader>fo', function() require('telescope.builtin').resume() end, desc = 'resume last picker' },
      { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = 'buffers' },
    },
    config = function()
      require('telescope').setup({
        defaults = {
          layout_strategy = 'horizontal',
          layout_config = { height = 0.30, prompt_position = 'top' },
          sorting_strategy = 'ascending',
          path_display = { 'truncate' },
        },
      })
      pcall(require('telescope').load_extension, 'fzf')

      vim.keymap.set('n', '<leader>fn', ':cnext<CR>', { silent = true, desc = 'next quickfix' })
      vim.keymap.set('n', '<leader>fp', ':cprev<CR>', { silent = true, desc = 'prev quickfix' })
    end,
  },
}
