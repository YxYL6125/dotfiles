-- ~/.config/nvim/lua/user/plugins/transparency.lua
return {
  "xiyaowong/transparent.nvim",
  -- 提前加载，确保命令在启动时可用
  lazy = false,
  opts = {
    groups = { "all" },
    exclude_groups = {},
  },
  config = function(_, opts)
    require("transparent").setup(opts)

    -- 这是解决问题的核心：创建一个在 Neovim 完全进入后才执行的自动命令
    vim.api.nvim_create_autocmd("VimEnter", {
      -- 确保这个自动命令组是唯一的，并且每次加载时都会被清空，避免重复创建
      group = vim.api.nvim_create_augroup("MyTransparentAutocmd", { clear = true }),
      pattern = "*",
      -- 使用 vim.defer_fn 来将命令推迟到下一个事件循环，确保它是最后执行的
      callback = function()
        vim.defer_fn(function()
          vim.cmd("TransparentEnable")
        end, 50) -- 50毫秒的延迟，足以等待所有UI刷新完成
      end,
    })
  end,
}
