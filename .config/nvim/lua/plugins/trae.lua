---@type LazySpec
return {
  {
    "https://code.byted.org/chenjiaqi.cposture/codeverse.vim.git",
    event = "InsertEnter",
    cmd = { "Trae", "Marscode", "Codeverse" },
    init = function()
      vim.g.trae_no_map_tab = true
    end,
    config = function()
      require("trae").setup {}

      local accept_or = function(fallback, desc)
        vim.keymap.set("i", fallback, ('trae#Accept("%s")'):format(vim.api.nvim_replace_termcodes(fallback, true, true, true)), {
          expr = true,
          replace_keycodes = false,
          silent = true,
          desc = desc,
        })
      end

      accept_or("<Right>", "Accept Trae suggestion or move right")
      accept_or("<C-l>", "Accept Trae suggestion or move right")
    end,
  },
}
