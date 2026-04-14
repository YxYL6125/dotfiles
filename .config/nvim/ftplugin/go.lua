local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = 0, desc = desc }) end
local lang = require "config.lang"

map("<leader>dt", function() require("dap-go").debug_test() end, "Go debug test")
map("<leader>dT", function() require("dap-go").debug_last_test() end, "Go debug last test")
map(
  "<leader>oi",
  function() lang.smart_code_action(0, { only = { "source.organizeImports" }, apply = true, notify = false }) end,
  "Go organize imports"
)
