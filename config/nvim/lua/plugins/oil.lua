return {
  {
    'stevearc/oil.nvim',
    cmd = 'Oil',
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'open parent dir' },
    },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    opts = {
      view_options = { show_hidden = true },
      keymaps = {
        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['<C-s>'] = 'actions.select_split',
        ['<C-v>'] = 'actions.select_vsplit',
        ['-'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
      },
    },
  },
}
