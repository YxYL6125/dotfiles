local function git_root(startpath)
  local cwd = startpath
  if not cwd or cwd == "" then
    local file = vim.api.nvim_buf_get_name(0)
    cwd = file ~= "" and vim.fn.fnamemodify(file, ":p:h") or vim.fn.getcwd()
  end
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

local git_workspace = require "config.git_workspace"

local function current_git_root()
  local file = vim.api.nvim_buf_get_name(0)
  local path = file ~= "" and vim.fn.fnamemodify(file, ":p:h") or vim.fn.getcwd()
  return git_root(path)
end

local function open_lazygit(root)
  local astro = require "astrocore"
  local target_root = root or current_git_root()
  local cmd = target_root and ("cd " .. vim.fn.shellescape(target_root) .. " && lazygit") or "lazygit"
  astro.toggle_term_cmd { cmd = cmd, direction = "float" }
end

local function open_neogit(args, root)
  require("lazy").load { plugins = { "neogit" } }
  local opts = vim.tbl_extend("force", { kind = "floating" }, args or {})
  opts.cwd = root or opts.cwd or current_git_root()
  require("neogit").open(opts)
end

local function open_workspace_overview()
  git_workspace.workspace_panel(current_git_root())
end

local function open_workspace_repos()
  git_workspace.workspace_repos(current_git_root())
end

local function open_workspace_branches()
  git_workspace.workspace_branches(current_git_root())
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

local function git_mappings()
  return {
    ["<leader>gg"] = { open_lazygit, "Git panel (LazyGit)" },
    ["<leader>gn"] = { function() open_neogit { kind = "floating" } end, "Git status (Neogit)" },
    ["<leader>gc"] = { function() open_neogit { "commit", kind = "floating" } end, "Git commit" },
    ["<leader>gb"] = { function() require("snacks").picker.git_branches() end, "Git branches" },
    ["<leader>gO"] = { open_workspace_overview, "Git workspace overview" },
    ["<leader>gW"] = { open_workspace_branches, "Git workspace branches" },
    ["<leader>gw"] = { open_workspace_repos, "Git workspace repos" },
    ["<leader>ge"] = { open_changed_files, "Git changed files" },
    ["<leader>gh"] = { function() require("snacks").picker.git_log() end, "Git history" },
    ["<leader>gf"] = { function() require("snacks").picker.git_log_file() end, "Git file history" },
    ["<leader>gF"] = { open_current_file_history, "Git file history (Diffview)" },
    ["<leader>gi"] = { function() require("snacks").picker.git_files() end, "Git tracked files" },
    ["<leader>go"] = { function() require("snacks").gitbrowse.open() end, "Git open remote", { "n", "x" } },
    ["<leader>gD"] = { "<cmd>DiffviewOpen<cr>", "Git diff view" },
    ["<leader>gH"] = { "<cmd>DiffviewFileHistory<cr>", "Git repo history" },
    ["<leader>gq"] = { "<cmd>DiffviewClose<cr>", "Git close diff view" },
    ["<leader>gm"] = {
      function()
        require("lazy").load { plugins = { "git-conflict.nvim" } }
        vim.cmd "GitConflictListQf"
      end,
      "Git merge conflicts",
    },
    ["<leader>gv"] = { open_branch_review, "Git review branch vs base" },
    ["<leader>gB"] = { toggle_current_line_blame, "Git toggle blame" },
    ["<leader>gV"] = { show_line_commit_popup, "Git line commit popup" },
  }
end

local function apply_git_keymaps(map)
  for lhs, spec in pairs(git_mappings()) do
    local rhs, desc, mode = spec[1], spec[2], spec[3] or "n"
    map(mode, lhs, rhs, desc)
  end
end

local function set_git_keymaps()
  if vim.g.custom_git_keymaps_applied then return end
  vim.g.custom_git_keymaps_applied = true

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
  end

  apply_git_keymaps(map)
end

return {
  {
    "akinsho/toggleterm.nvim",
    optional = true,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<leader>gg"] = { open_lazygit, desc = "Git panel (LazyGit)" }
    end,
  },
  {
    "AstroNvim/astrocore",
    optional = true,
    init = function()
      git_workspace.setup_commands()
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
      for lhs, spec in pairs(git_mappings()) do
        local rhs, desc = spec[1], spec[2]
        if spec[3] == nil or spec[3] == "n" then
          opts.mappings.n[lhs] = { rhs, desc = desc }
        end
      end
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
