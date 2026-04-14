local function git_root()
  local astro = require "astrocore"
  local worktree = astro.file_worktree()
  if worktree and worktree.toplevel then return worktree.toplevel end

  local file = vim.api.nvim_buf_get_name(0)
  local cwd = file ~= "" and vim.fn.fnamemodify(file, ":p:h") or vim.fn.getcwd()
  local root = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error == 0 and root and root ~= "" then return root end
end

local function git_system(root, args)
  if not root then return nil end
  local cmd = vim.list_extend({ "git", "-C", root }, args)
  local out = vim.fn.systemlist(cmd)
  return vim.v.shell_error == 0 and out or nil
end

local function detect_base_ref(root)
  local symbolic = git_system(root, { "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" })
  if symbolic and symbolic[1] and symbolic[1] ~= "" then return symbolic[1] end

  for _, ref in ipairs { "origin/main", "origin/master", "main", "master" } do
    local ok = git_system(root, { "rev-parse", "--verify", ref })
    if ok then return ref end
  end
end

local function open_lazygit()
  local astro = require "astrocore"
  local worktree = astro.file_worktree()
  local cmd = "lazygit"

  if worktree then
    cmd = (
      "lazygit --work-tree=%s --git-dir=%s"
    ):format(vim.fn.shellescape(worktree.toplevel), vim.fn.shellescape(worktree.gitdir))
  end

  astro.toggle_term_cmd { cmd = cmd, direction = "float" }
end

local function open_neogit(args)
  require("lazy").load { plugins = { "neogit" } }
  require("neogit").open(args or { kind = "floating" })
end

local function open_current_file_history()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Current buffer has no file path", vim.log.levels.WARN)
    return
  end
  vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(file))
end

local function open_branch_review()
  local root = git_root()
  if not root then
    vim.notify("Not inside a git worktree", vim.log.levels.WARN)
    return
  end

  local base = detect_base_ref(root)
  if not base then
    vim.notify("Could not detect base branch (tried origin/main, origin/master, main, master)", vim.log.levels.WARN)
    return
  end

  vim.notify("Diffview against " .. base, vim.log.levels.INFO)
  vim.cmd("DiffviewOpen " .. base .. "...HEAD")
end

local function open_changed_files()
  require("snacks").picker.git_status()
end

local function toggle_current_line_blame()
  require("lazy").load { plugins = { "gitsigns.nvim" } }
  require("gitsigns").toggle_current_line_blame()
end

local function show_line_commit_popup()
  require("snacks").git.blame_line { count = 20 }
end

local function set_git_keymaps()
  if vim.g.custom_git_keymaps_applied then return end
  vim.g.custom_git_keymaps_applied = true

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
  end

  map("n", "<leader>gg", open_lazygit, "Git panel (LazyGit)")
  map("n", "<leader>gn", function() open_neogit { kind = "floating" } end, "Git status (Neogit)")
  map("n", "<leader>gc", function() open_neogit { "commit", kind = "floating" } end, "Git commit")
  map("n", "<leader>gb", function() require("snacks").picker.git_branches() end, "Git branches")
  map("n", "<leader>ge", open_changed_files, "Git changed files")
  map("n", "<leader>gh", function() require("snacks").picker.git_log() end, "Git history")
  map("n", "<leader>gf", function() require("snacks").picker.git_log_file() end, "Git file history")
  map("n", "<leader>gF", open_current_file_history, "Git file history (Diffview)")
  map("n", "<leader>gi", function() require("snacks").picker.git_files() end, "Git tracked files")
  map({ "n", "x" }, "<leader>go", function() require("snacks").gitbrowse.open() end, "Git open remote")
  map("n", "<leader>gD", "<cmd>DiffviewOpen<cr>", "Git diff view")
  map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", "Git repo history")
  map("n", "<leader>gq", "<cmd>DiffviewClose<cr>", "Git close diff view")
  map("n", "<leader>gm", function()
    require("lazy").load { plugins = { "git-conflict.nvim" } }
    vim.cmd "GitConflictListQf"
  end, "Git merge conflicts")
  map("n", "<leader>gv", open_branch_review, "Git review branch vs base")
  map("n", "<leader>gB", toggle_current_line_blame, "Git toggle blame")
  map("n", "<leader>gV", show_line_commit_popup, "Git line commit popup")
end

return {
  {
    "AstroNvim/astrocore",
    optional = true,
    init = function()
      local group = vim.api.nvim_create_augroup("custom_git_keymaps", { clear = true })
      vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function() vim.schedule(set_git_keymaps) end,
      })
      if vim.v.vim_did_enter == 1 then vim.schedule(set_git_keymaps) end
    end,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<leader>g"] = vim.tbl_get(opts, "_map_sections", "g") or { desc = "Git" }
    end,
  },
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewToggleFiles",
      "DiffviewRefresh",
    },
    config = function(_, opts) require("diffview").setup(opts) end,
    opts = {
      enhanced_diff_hl = true,
      use_icons = true,
      view = {
        default = { winbar_info = true },
        merge_tool = { layout = "diff3_horizontal" },
      },
      file_panel = { win_config = { position = "left", width = 38 } },
    },
  },
  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "folke/snacks.nvim",
    },
    config = function(_, opts) require("neogit").setup(opts) end,
    opts = {
      kind = "floating",
      disable_insert_on_commit = "auto",
      graph_style = "unicode",
      integrations = {
        diffview = true,
        snacks = true,
      },
    },
  },
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    cmd = {
      "GitConflictChooseOurs",
      "GitConflictChooseTheirs",
      "GitConflictChooseBoth",
      "GitConflictChooseNone",
      "GitConflictNextConflict",
      "GitConflictPrevConflict",
      "GitConflictListQf",
    },
    event = "BufReadPost",
    config = function(_, opts) require("git-conflict").setup(opts) end,
    opts = {
      default_mappings = true,
      default_commands = true,
      disable_diagnostics = false,
      list_opener = "copen",
    },
  },
}
