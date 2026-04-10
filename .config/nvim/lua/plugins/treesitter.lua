-- Treesitter configuration activated

-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "go",
      "gomod",
      "gosum",
      "gowork",
      "lua",
      "query",
      "thrift",
      "vim",
      "java", -- Java语法支持
      "python", -- Python 语法支持
      -- add more arguments for adding more treesitter parsers
    },
  },
}
