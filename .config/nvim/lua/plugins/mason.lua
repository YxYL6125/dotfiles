-- Mason configuration activated

-- Customize Mason

---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      run_on_start = false,
      start_delay = 3000,
      debounce_hours = 12,
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- install language servers
        "lua-language-server",
        "jdtls", -- Java Language Server
        "pyright", -- Python LSP
        "rust-analyzer", -- Rust LSP

        -- install formatters
        "stylua",
        "black",
        "isort",

        -- install linters
        "golangci-lint",
        "ruff",
        "mypy",

        -- install debuggers
        "debugpy",
        "java-debug-adapter", -- Java调试器
        "java-test", -- Java测试运行器
        "codelldb", -- Rust 调试器

        -- install any other package
        "tree-sitter-cli",
      },
    },
  },
}
