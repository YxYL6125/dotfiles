local data = require "config.git_workspace_data"
local pickers = require "config.git_workspace_pickers"
local panel = require "config.git_workspace_panel"

local M = {
  detect_workspace = data.detect_workspace,
  collect_repos = data.collect_repos,
  collect_branch_groups = data.collect_branch_groups,
  collect_branches = data.collect_branches,
  workspace_repos = pickers.workspace_repos,
  workspace_overview = pickers.workspace_overview,
  branch_group_repos = pickers.branch_group_repos,
  repo_branches = pickers.repo_branches,
  workspace_branches = pickers.workspace_branches,
  workspace_panel = panel.workspace_panel,
}

function M.setup_commands()
  local function command(name, rhs, opts)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, rhs, opts)
  end

  command("GitWorkspacePanel", function(params)
    M.workspace_panel(params.args ~= "" and params.args or nil)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "Open fixed two-pane branch/repo workspace panel",
  })

  command("GitWorkspaceOverview", function(params)
    M.workspace_overview(params.args ~= "" and params.args or nil)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "List current branches and their repos in current workspace",
  })

  command("GitWorkspaceRepos", function(params)
    M.workspace_repos(params.args ~= "" and params.args or nil)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "List sibling git repositories in current workspace",
  })

  command("GitWorkspaceBranches", function(params)
    M.workspace_branches(params.args ~= "" and params.args or nil)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "List local branches across current workspace repos",
  })
end

return M
