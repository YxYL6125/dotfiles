local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = 0, desc = desc }) end
local lang = require "config.lang"

map("<leader>pr", function() require("dap-python").test_method() end, "Python debug method")
map("<leader>pR", function() require("dap-python").test_class() end, "Python debug class")
map("<leader>pf", function() require("dap-python").debug_selection() end, "Python debug selection")
map(
  "<leader>pi",
  function()
    lang.smart_code_action(0, { only = { "source.organizeImports" }, apply = true, notify = false })
  end,
  "Python organize imports"
)
