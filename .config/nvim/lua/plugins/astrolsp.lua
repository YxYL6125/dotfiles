---@type LazySpec
return {
  "AstroNvim/astrolsp",
  version = false,
  ---@type AstroLSPOpts
  opts = {
    features = {
      codelens = true,
      inlay_hints = false,
      semantic_tokens = true,
    },
    formatting = {
      format_on_save = {
        enabled = true,
        allow_filetypes = {},
        ignore_filetypes = {},
      },
      disabled = {},
      timeout_ms = 1000,
    },
    servers = {
      "gopls",
      "pyright",
      "rust_analyzer",
      "thriftls",
    },
    ---@diagnostic disable: missing-fields
    config = {
      gopls = {
        settings = {
          gopls = {
            analyses = {
              fieldalignment = true,
              nilness = true,
              shadow = true,
              unusedparams = true,
            },
            codelenses = {
              gc_details = true,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
            },
            completeUnimported = true,
            directoryFilters = { "-.git", "-.idea", "-.vscode", "-node_modules" },
            gofumpt = true,
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            semanticTokens = true,
            staticcheck = true,
            usePlaceholders = true,
          },
        },
      },
      pyright = {
        settings = {
          pyright = {
            disableOrganizeImports = false,
          },
          python = {
            analysis = {
              autoImportCompletions = true,
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              typeCheckingMode = "basic",
              useLibraryCodeForTypes = true,
            },
          },
        },
      },
      rust_analyzer = {
        cmd = { "/Users/bytedance/.local/share/nvim/mason/bin/rust-analyzer" },
      },
      thriftls = {
        cmd = { require("config.lang").resolve_thriftls() or "thriftls" },
        filetypes = { "thrift" },
        root_dir = function(bufnr, on_dir)
          local util = require "lspconfig.util"
          local fname = vim.api.nvim_buf_get_name(bufnr)
          on_dir(util.root_pattern(".git", "buf.yaml", "buf.work.yaml")(fname) or vim.fs.dirname(fname))
        end,
      },
    },
    autocmds = {
      lsp_codelens_refresh = {
        cond = "textDocument/codeLens",
        {
          event = { "InsertLeave", "BufEnter" },
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then vim.lsp.codelens.refresh { bufnr = args.buf } end
          end,
        },
      },
      go_format_on_save = {
        {
          event = "BufWritePre",
          desc = "Go organize imports + format",
          callback = function(args)
            local bufnr = args.buf
            if vim.bo[bufnr].filetype ~= "go" then return end
            vim.lsp.buf.code_action {
              bufnr = bufnr,
              context = { only = { "source.organizeImports" }, diagnostics = {} },
              apply = true,
            }
            vim.lsp.buf.format { bufnr = bufnr, async = false }
          end,
        },
      },
    },
    mappings = {
      n = {
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        gd = {
          function() vim.lsp.buf.definition() end,
          desc = "Show definition",
          cond = "textDocument/definition",
        },
        gi = {
          function() vim.lsp.buf.implementation() end,
          desc = "Show implementations",
          cond = "textDocument/implementation",
        },
        gr = {
          function() vim.lsp.buf.references() end,
          desc = "Show references",
          cond = "textDocument/references",
        },
        gy = {
          function() vim.lsp.buf.type_definition() end,
          desc = "Show type definition",
          cond = "textDocument/typeDefinition",
        },
        ["<leader>cr"] = {
          function() vim.lsp.buf.rename() end,
          desc = "Rename symbol",
          cond = "textDocument/rename",
        },
        ["<leader>ca"] = {
          function() vim.lsp.buf.code_action() end,
          desc = "Code actions",
          cond = "textDocument/codeAction",
        },
        K = {
          function() vim.lsp.buf.hover() end,
          desc = "Hover symbol details",
          cond = "textDocument/hover",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client.supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
      },
    },
  },
}
