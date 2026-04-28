return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add          = { text = '+' },
        change       = { text = '~' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
      },
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end
        map('<leader>diff', gs.diffthis, 'git diff')
        map(']c', function() gs.nav_hunk('next') end, 'next hunk')
        map('[c', function() gs.nav_hunk('prev') end, 'prev hunk')
        map('<leader>hp', gs.preview_hunk, 'preview hunk')
        map('<leader>hr', gs.reset_hunk, 'reset hunk')
        map('<leader>hb', function() gs.blame_line({ full = true }) end, 'blame line')
      end,
    },
  },
}
