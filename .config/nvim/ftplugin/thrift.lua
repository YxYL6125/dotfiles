local lang = require "config.lang"

local function map(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = 0, desc = desc }) end

map("<C-]>", function() lang.smart_lsp_jump(0) end, "Smart go to Thrift definition")
map("gd", function() lang.thrift_definition_or_search(0) end, "Thrift definition")
map("gr", function() lang.thrift_references_or_search(0, { include_declaration = false }) end, "Thrift usages")
map(
  "gR",
  function() lang.thrift_references_or_search(0, { include_declaration = true }) end,
  "Thrift references including declaration"
)
map("<leader>cu", function() lang.thrift_references_or_search(0, { include_declaration = false }) end, "Thrift usages")
