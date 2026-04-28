return {
  {
    'saghen/blink.cmp',
    version = '*',  -- 用 release，不用 main
    event = 'InsertEnter',
    opts = {
      keymap = { preset = 'default' },
      appearance = {
        nerd_font_variant = 'mono',
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      signature = { enabled = true },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
    },
  },
}
