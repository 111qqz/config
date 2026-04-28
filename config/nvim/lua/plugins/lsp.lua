return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'b0o/SchemaStore.nvim',
      'saghen/blink.cmp',
    },
    config = function()
      require('mason-tool-installer').setup({
        ensure_installed = {
          'clangd', 'basedpyright', 'lua-language-server', 'bash-language-server',
          'marksman', 'json-lsp', 'yaml-language-server', 'taplo',
          'dockerfile-language-server', 'docker-compose-language-service',
          'clang-format', 'ruff', 'stylua', 'shfmt', 'prettier',
          'shellcheck', 'markdownlint', 'yamllint', 'hadolint', 'cppcheck',
        },
        run_on_start = true,
      })

      local lspconfig = require('lspconfig')
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
        end
        map('gd', vim.lsp.buf.definition, 'goto definition')
        map('gD', vim.lsp.buf.declaration, 'goto declaration')
        map('gI', vim.lsp.buf.implementation, 'goto implementation')
        map('gr', function() require('telescope.builtin').lsp_references() end, 'references')
        map('K', vim.lsp.buf.hover, 'hover docs')
        map('<leader>D', vim.lsp.buf.type_definition, 'type definition')
        map('<leader>rn', vim.lsp.buf.rename, 'rename')
        map('<leader>ca', vim.lsp.buf.code_action, 'code action')
        map('<leader>e', vim.diagnostic.open_float, 'show diagnostic')
        map(']d', function() vim.diagnostic.jump({ count = 1 }) end, 'next diagnostic')
        map('[d', function() vim.diagnostic.jump({ count = -1 }) end, 'prev diagnostic')
        map('<leader>fr', function() require('telescope.builtin').lsp_references() end, 'references')
        map('<leader>fd', vim.lsp.buf.definition, 'definitions')
      end

      local servers = {
        clangd = {
          cmd = {
            'clangd', '--background-index', '--clang-tidy',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
            '--function-arg-placeholders=true',
          },
          init_options = { fallbackFlags = { '-std=c++20', '-Wall', '-Wextra' } },
        },
        basedpyright = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
              diagnostics = { globals = { 'vim' } },
            },
          },
        },
        bashls = {},
        marksman = {},
        jsonls = {
          settings = {
            json = {
              schemas = require('schemastore').json.schemas(),
              validate = { enable = true },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemaStore = { enable = false, url = '' },
              schemas = require('schemastore').yaml.schemas(),
            },
          },
        },
        taplo = {},
        dockerls = {},
        docker_compose_language_service = {},
      }

      for name, cfg in pairs(servers) do
        cfg.capabilities = capabilities
        cfg.on_attach = on_attach
        local ok, err = pcall(function() lspconfig[name].setup(cfg) end)
        if not ok then
          vim.notify('lspconfig setup failed for ' .. name .. ': ' .. tostring(err), vim.log.levels.WARN)
        end
      end

      vim.diagnostic.config({
        virtual_text = { prefix = '●' },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = '✘',
            [vim.diagnostic.severity.WARN]  = '⚠',
            [vim.diagnostic.severity.INFO]  = '●',
            [vim.diagnostic.severity.HINT]  = '●',
          },
        },
        update_in_insert = false,
      })
    end,
  },
}
