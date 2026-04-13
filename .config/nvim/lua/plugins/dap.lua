-- ~/.config/nvim/plugins/dap.lua
-- nvim-dap 核心与 UI、快捷键统一
return {
  { "mfussenegger/nvim-dap" },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require "dap", require "dapui"

      dapui.setup {
        layouts = {
          { elements = { "scopes", "breakpoints", "stacks", "watches" }, size = 40, position = "left" },
          { elements = { "repl", "console" }, size = 10, position = "bottom" },
        },
        controls = { enabled = true, element = "repl" },
      }
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      local lang = require "config.lang"
      dap.adapters.codelldb = {
        type = "executable",
        command = lang.resolve_codelldb(),
      }
      dap.configurations.rust = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function() return lang.resolve_rust_debug_executable() end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      -- 通用快捷键（正常模式）
      local map = function(keys, cmd, desc) vim.keymap.set("n", keys, cmd, { desc = "DAP: " .. desc }) end
      map("<F5>", function() dap.continue() end, "继续/启动")
      map("<F6>", function() dap.run_last() end, "运行上次配置")
      map("<F10>", function() dap.step_over() end, "Step Over")
      map("<F11>", function() dap.step_into() end, "Step Into")
      map("<F12>", function() dap.step_out() end, "Step Out")
      map("<leader>db", function() dap.toggle_breakpoint() end, "切换断点")
      map("<leader>dB", function() dap.set_breakpoint(vim.fn.input "条件断点表达式: ") end, "条件断点")
      map("<leader>dr", function() dap.restart() end, "重启会话")
      map("<leader>dx", function() dap.terminate() end, "终止会话")
      map("<leader>de", function() dapui.eval() end, "评估变量")

      dap.defaults.fallback.terminal_win_cmd = "50vsplit new"
    end,
  },
}
