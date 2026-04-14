return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      local function has_words_before()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        local before = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1] or ""
        return before:sub(col, col):match "%S" ~= nil
      end

      opts.keymap = opts.keymap or {}
      opts.keymap["<Tab>"] = {
        "select_and_accept",
        "snippet_forward",
        function(cmp)
          if has_words_before() or vim.api.nvim_get_mode().mode == "c" then return cmp.show() end
        end,
        "fallback",
      }
    end,
  },
}
