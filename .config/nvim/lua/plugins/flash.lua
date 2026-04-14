-- ~/.config/nvim/lua/user/plugins/flash-custom.lua
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {}, -- AstroNvim handles the default options, we just need to set keys
  -- The 'keys' table is the most important part.
  -- This will properly override the default AstroNvim keymaps.
  keys = {
    {
      "<leader>fw",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump {
          search = {
            mode = "word",
          },
        }
      end,
      desc = "Flash: Word",
    },
    {
      "<leader>fc",
      mode = { "n", "x", "o" },
      function() require("flash").jump { search = { mode = "char" } } end,
      desc = "Flash: Char Search",
    },
    -- You can add the rest of your desired keys here (f, t, l, b, etc.)
    -- just like in the previous full configuration file I provided.
  },
}
