return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    branch = 'master', -- nvim-0.10-compat branch (uses gcc, not tree-sitter CLI)
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'c', 'cpp', 'python', 'lua', 'bash',
        'markdown', 'markdown_inline',
        'json', 'yaml', 'toml', 'dockerfile',
        'vim', 'vimdoc', 'regex', 'gitcommit', 'diff',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    event = { 'BufReadPost', 'BufNewFile' },
  },
}
