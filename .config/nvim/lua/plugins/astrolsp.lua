local lang = require "config.lang"

local function go_organize_imports_and_format(bufnr)
  if vim.bo[bufnr].filetype ~= "go" then return end
  if vim.tbl_isempty(vim.lsp.get_clients { bufnr = bufnr, name = "gopls" }) then return end

  lang.smart_code_action(bufnr, {
    only = { "source.organizeImports" },
    apply = true,
    notify = false,
  })
  vim.lsp.buf.format { bufnr = bufnr, async = false }
end

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
    handlers = {
      -- Java is started from ftplugin/java.lua through nvim-jdtls.
      -- Do not let Mason/AstroLSP also start the generic jdtls config.
      jdtls = false,
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
        cmd = { require("config.lang").resolve_rust_analyzer() },
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
          desc = "Go organize imports + format via gopls",
          callback = function(args) go_organize_imports_and_format(args.buf) end,
        },
      },
    },
    mappings = {
      n = {
        ["<C-]>"] = {
          function() lang.smart_lsp_jump(0) end,
          desc = "Smart go to implementation/definition",
        },
        gD = {
          function() lang.lsp_location("declaration", 0) end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        gd = {
          function() lang.lsp_location("definition", 0) end,
          desc = "Show definition",
          cond = "textDocument/definition",
        },
        gi = {
          function() lang.lsp_location("implementation", 0) end,
          desc = "Show implementations",
          cond = "textDocument/implementation",
        },
        gr = {
          function() lang.lsp_location("references", 0, { include_declaration = false }) end,
          desc = "Find usages",
        },
        gR = {
          function() lang.lsp_location("references", 0, { include_declaration = true }) end,
          desc = "Show references including declaration",
        },
        gy = {
          function() lang.lsp_location("type_definition", 0) end,
          desc = "Show type definition",
          cond = "textDocument/typeDefinition",
        },
        ["<leader>cr"] = {
          function() vim.lsp.buf.rename() end,
          desc = "Rename symbol",
          cond = "textDocument/rename",
        },
        ["<leader>ca"] = {
          function() lang.smart_code_action(0) end,
          desc = "Code actions",
          cond = "textDocument/codeAction",
        },
        ["<leader>cu"] = {
          function() lang.lsp_location("references", 0, { include_declaration = false }) end,
          desc = "Find usages",
        },
        ["<leader>cI"] = {
          function() lang.lsp_call_hierarchy("incoming_calls", 0) end,
          desc = "Incoming calls",
          cond = "textDocument/prepareCallHierarchy",
        },
        ["<leader>cO"] = {
          function() lang.lsp_call_hierarchy("outgoing_calls", 0) end,
          desc = "Outgoing calls",
          cond = "textDocument/prepareCallHierarchy",
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
            return client:supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
      },
    },
  },
}
