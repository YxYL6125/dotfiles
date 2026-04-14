---@type LazySpec
return {
  "AstroNvim/astrocore",
  version = false,
  ---@type AstroCoreOpts
  opts = {
    features = {
      large_buf = { size = 1024 * 512, lines = 20000 },
      autopairs = true,
      cmp = true,
      diagnostics = { virtual_text = true, virtual_lines = false },
      highlighturl = true,
      notifications = true,
    },
    diagnostics = {
      virtual_text = true,
      underline = true,
      severity_sort = true,
    },
    options = {
      opt = {
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = false,
        tabstop = 2,
        shiftwidth = 2,
        softtabstop = 2,
        expandtab = true,
        smartcase = true,
        ignorecase = true,
      },
    },
    mappings = {
      n = {
        ["<leader><leader>"] = {
          function() require("snacks").picker.files() end,
          desc = "Search files",
        },
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },
        ["<Leader>bn"] = { "<cmd>enew<cr>", desc = "New buffer" },
        ["<Leader>ff"] = {
          function() require("snacks").picker.files() end,
          desc = "Find files",
        },
        ["<Leader>fg"] = {
          function() require("snacks").picker.grep() end,
          desc = "Find text",
        },
        ["<Leader>fr"] = {
          function() require("snacks").picker.recent() end,
          desc = "Recent files",
        },
        ["<Leader>fs"] = {
          function() require("snacks").picker.lsp_symbols() end,
          desc = "Workspace symbols",
        },
        ["<Leader>fd"] = {
          function() require("snacks").picker.diagnostics_buffer() end,
          desc = "Buffer diagnostics",
        },
        ["<Leader>tt"] = { "<cmd>ToggleTerm direction=float<cr>", desc = "Floating terminal" },
        ["<Leader>cA"] = { "<cmd>CloudDevAttach<cr>", desc = "Cloud Dev attach workspace" },
        ["<Leader>cB"] = { "<cmd>CloudDevBind<cr>", desc = "Cloud Dev bind workspace" },
        ["<Leader>cE"] = { "<cmd>CloudDevSelect<cr>", desc = "Cloud Dev select environment" },
        ["<Leader>cS"] = { "<cmd>CloudDevStatus<cr>", desc = "Cloud Dev status" },
        ["<Leader>cU"] = { "<cmd>CloudDevUnbind<cr>", desc = "Cloud Dev unbind workspace" },
        ["<Leader>w"] = { "<cmd>w<cr>", desc = "Save file" },
      },
    },
  },
}
