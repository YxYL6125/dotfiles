-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"
    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      null_ls.builtins.formatting.gofumpt,
      null_ls.builtins.formatting.goimports,
      -- Python 格式化/导入
      null_ls.builtins.formatting.black,
      null_ls.builtins.formatting.isort,
      -- Python 诊断/静态检查
      null_ls.builtins.diagnostics.ruff,
      null_ls.builtins.diagnostics.mypy,
    })
  end,
}
