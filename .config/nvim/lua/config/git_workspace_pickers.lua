local util = require "config.git_workspace_util"
local data = require "config.git_workspace_data"
local actions = require "config.git_workspace_actions"
local previews = require "config.git_workspace_previews"

local M = {}

local function branch_group_actions()
  return {
    open_group = function(_, item) M.branch_group_repos(actions.with_entry(item)) end,
    batch_pull = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.run_group_git_command(entry, { "pull", "--ff-only" }, "batch pull --ff-only") end
    end,
    batch_fetch = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.run_group_git_command(entry, { "fetch", "--all", "--prune" }, "batch fetch --all --prune") end
    end,
  }
end

local function repo_actions()
  return {
    open_branches = function(_, item) M.repo_branches(actions.with_entry(item)) end,
    status = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_snacks_picker("git_status", entry.root) end
    end,
    log = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_snacks_picker("git_log", entry.root) end
    end,
    files = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_snacks_picker("git_files", entry.root) end
    end,
    neogit = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_neogit(entry.root) end
    end,
    lazygit = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_lazygit(entry.root) end
    end,
  }
end

local function branch_actions()
  return {
    checkout = function(_, item) actions.checkout_branch(item) end,
    status = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_snacks_picker("git_status", entry.root) end
    end,
    log = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_snacks_picker("git_log", entry.root) end
    end,
    neogit = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_neogit(entry.root) end
    end,
    lazygit = function(_, item)
      local entry = actions.with_entry(item)
      if entry then actions.open_lazygit(entry.root) end
    end,
  }
end

function M.workspace_repos(explicit_path)
  local ctx, repos = data.collect_repos(explicit_path)
  if #repos == 0 then
    util.notify("当前路径附近没找到多仓库工作区: " .. (ctx.root or vim.fn.getcwd()), vim.log.levels.WARN)
    return
  end

  util.picker_select(repos, {
    prompt = "Git workspace repos › " .. ctx.root,
    format_item = function(repo)
      local dirty = (repo.conflicts + repo.staged + repo.unstaged + repo.untracked) > 0 and "●" or "○"
      return string.format("%s %-24s %-24s %-8s %s", dirty, repo.name, repo.branch or "(unknown)", repo.track or "=", repo.status)
    end,
    preview = previews.repo,
    keys = {
      ["<C-s>"] = { "status", mode = { "n", "i" } },
      ["<C-h>"] = { "log", mode = { "n", "i" } },
      ["<C-f>"] = { "files", mode = { "n", "i" } },
      ["<C-n>"] = { "neogit", mode = { "n", "i" } },
      ["<C-g>"] = { "lazygit", mode = { "n", "i" } },
    },
    actions = repo_actions(),
  }, function(repo)
    if repo then M.repo_branches(repo) end
  end)
end

function M.workspace_overview(explicit_path)
  local ctx, groups = data.collect_branch_groups(explicit_path)
  if #groups == 0 then
    util.notify("当前路径附近没找到多仓库工作区: " .. (ctx.root or vim.fn.getcwd()), vim.log.levels.WARN)
    return
  end

  util.picker_select(groups, {
    prompt = "Git workspace overview › " .. ctx.root,
    format_item = function(group)
      local current = group.current and "*" or " "
      local dirty = (group.dirty or 0) > 0 and (" dirty:" .. group.dirty) or ""
      local track = ((group.ahead or 0) > 0 and (" ↑" .. group.ahead) or "") .. ((group.behind or 0) > 0 and (" ↓" .. group.behind) or "")
      local repos = table.concat(group.repo_names or {}, ", ")
      return string.format("%s %-28s [%2d repos]%s%s  %s", current, group.branch, #group.repos, dirty, track, repos)
    end,
    preview = previews.branch_group,
    keys = {
      ["<C-p>"] = { "batch_pull", mode = { "n", "i" } },
      ["<C-u>"] = { "batch_fetch", mode = { "n", "i" } },
    },
    actions = branch_group_actions(),
  }, function(group)
    if group then M.branch_group_repos(group) end
  end)
end

function M.branch_group_repos(group)
  local entry = actions.with_entry(group)
  if not entry then
    util.notify("没有选中 branch 分组", vim.log.levels.WARN)
    return
  end
  util.picker_select(entry.repos, {
    prompt = "Git branch group repos › " .. entry.branch,
    format_item = function(repo)
      local dirty = (repo.conflicts + repo.staged + repo.unstaged + repo.untracked) > 0 and "●" or "○"
      return string.format("%s %-24s %-8s %s", dirty, repo.name, repo.track or "=", repo.status)
    end,
    preview = previews.repo,
    keys = {
      ["<C-s>"] = { "status", mode = { "n", "i" } },
      ["<C-h>"] = { "log", mode = { "n", "i" } },
      ["<C-f>"] = { "files", mode = { "n", "i" } },
      ["<C-n>"] = { "neogit", mode = { "n", "i" } },
      ["<C-g>"] = { "lazygit", mode = { "n", "i" } },
      ["<C-p>"] = { "batch_pull", mode = { "n", "i" } },
      ["<C-u>"] = { "batch_fetch", mode = { "n", "i" } },
    },
    actions = vim.tbl_extend("force", repo_actions(), {
      batch_pull = function() actions.run_group_git_command(entry, { "pull", "--ff-only" }, "batch pull --ff-only") end,
      batch_fetch = function() actions.run_group_git_command(entry, { "fetch", "--all", "--prune" }, "batch fetch --all --prune") end,
    }),
  }, function(repo)
    if repo then M.repo_branches(repo) end
  end)
end

function M.repo_branches(repo)
  local entry = actions.with_entry(repo)
  if not entry then
    util.notify("没有选中仓库", vim.log.levels.WARN)
    return
  end

  local _, branches = data.collect_branches(entry.root, { repo = entry.name })
  if #branches == 0 then
    util.notify("仓库没有本地 branches: " .. entry.name, vim.log.levels.WARN)
    return
  end

  util.picker_select(branches, {
    prompt = "Git branches › " .. entry.name,
    format_item = function(item)
      local current = item.current and "*" or " "
      local track = item.track and ("  " .. item.track) or ""
      local subject = item.subject ~= "" and ("  ·  " .. item.subject) or ""
      return string.format("%s %-28s (%s)%s%s", current, item.branch, item.repo, track, subject)
    end,
    preview = previews.branch,
    keys = {
      ["<C-s>"] = { "status", mode = { "n", "i" } },
      ["<C-h>"] = { "log", mode = { "n", "i" } },
      ["<C-n>"] = { "neogit", mode = { "n", "i" } },
      ["<C-g>"] = { "lazygit", mode = { "n", "i" } },
    },
    actions = branch_actions(),
  }, actions.checkout_branch)
end

function M.workspace_branches(explicit_path)
  local ctx, items = data.collect_branches(explicit_path)
  if #items == 0 then
    util.notify("当前工作区没找到本地 branches: " .. (ctx.root or vim.fn.getcwd()), vim.log.levels.WARN)
    return
  end

  util.picker_select(items, {
    prompt = "Git workspace branches › " .. ctx.root,
    format_item = function(item)
      local current = item.current and "*" or " "
      local track = item.track and ("  " .. item.track) or ""
      local subject = item.subject ~= "" and ("  ·  " .. item.subject) or ""
      return string.format("%s %-26s (%-20s)%s%s", current, item.branch, item.repo, track, subject)
    end,
    preview = previews.branch,
    keys = {
      ["<C-s>"] = { "status", mode = { "n", "i" } },
      ["<C-h>"] = { "log", mode = { "n", "i" } },
      ["<C-n>"] = { "neogit", mode = { "n", "i" } },
      ["<C-g>"] = { "lazygit", mode = { "n", "i" } },
    },
    actions = branch_actions(),
  }, actions.checkout_branch)
end

return M
