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
    autocmds = {
      autosave = {
        {
          event = { "InsertLeave", "BufLeave", "FocusLost" },
          desc = "Autosave file buffers",
          callback = function(args)
            local bufnr = args.buf
            if not vim.api.nvim_buf_is_valid(bufnr) then return end
            if not vim.bo[bufnr].modified or not vim.bo[bufnr].modifiable or vim.bo[bufnr].readonly then return end
            if vim.bo[bufnr].buftype ~= "" then return end
            if vim.api.nvim_buf_get_name(bufnr) == "" then return end
            vim.api.nvim_buf_call(bufnr, function() vim.cmd "silent! update" end)
          end,
        },
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
      },
    },
  },
}
