-- ~/.config/nvim/lua/user/plugins/flash-custom.lua
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  config = function(_, opts)
    require("flash").setup(opts)

    local function map(lhs, rhs, desc)
      vim.keymap.set({ "n", "x", "o" }, lhs, rhs, { desc = desc })
    end

    map("<leader>w", function()
      require("flash").jump {
        search = {
          mode = "word",
        },
      }
    end, "Flash: Word")

    map("<leader>s", function()
      require("flash").jump { search = { mode = "char" } }
    end, "Flash: Char Search")

    -- You can add the rest of your desired keys here (f, t, l, b, etc.)
    -- just like in the previous full configuration file I provided.
  end,
}
