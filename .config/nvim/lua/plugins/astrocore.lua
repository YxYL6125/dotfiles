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
        ["<leader>ff"] = {
          function() require("snacks").picker.files() end,
          desc = "Find files",
        },
        ["<leader>fg"] = {
          function() require("snacks").picker.grep() end,
          desc = "Find text",
        },
        ["<leader>fr"] = {
          function() require("snacks").picker.recent() end,
          desc = "Recent files",
        },
        ["<leader>fs"] = {
          function() require("snacks").picker.lsp_symbols() end,
          desc = "Workspace symbols",
        },
        ["<leader>fd"] = {
          function() require("snacks").picker.diagnostics_buffer() end,
          desc = "Buffer diagnostics",
        },
        ["<leader>tt"] = { "<cmd>ToggleTerm direction=float<cr>", desc = "Floating terminal" },
        ["<leader>w"] = {
          function() require("flash").jump { search = { mode = "word" } } end,
          desc = "Flash word jump",
        },
        ["<leader>s"] = {
          function() require("flash").jump { search = { mode = "char" } } end,
          desc = "Flash char search",
        },
        ["<M-CR>"] = {
          function() require("config.lang").smart_code_action(0) end,
          desc = "Code actions",
        },
        ["<A-CR>"] = {
          function() require("config.lang").smart_code_action(0) end,
          desc = "Code actions",
        },
        ["<Leader>cA"] = { "<cmd>CloudDevAttach<cr>", desc = "Cloud Dev attach workspace" },
        ["<Leader>cB"] = { "<cmd>CloudDevBind<cr>", desc = "Cloud Dev bind workspace" },
        ["<Leader>cE"] = { "<cmd>CloudDevSelect<cr>", desc = "Cloud Dev select environment" },
        ["<Leader>cS"] = { "<cmd>CloudDevStatus<cr>", desc = "Cloud Dev status" },
        ["<Leader>cU"] = { "<cmd>CloudDevUnbind<cr>", desc = "Cloud Dev unbind workspace" },
        ["<C-s>"] = { "<cmd>w<cr>", desc = "Save file" },
      },
    },
  },
}
