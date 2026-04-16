local util = require "config.git_workspace_util"

local M = {}

function M.branch_group(group)
  if not group then return { "No preview" } end
  local lines = {
    "# " .. group.branch,
    "",
    "- Workspace: `" .. (group.workspace_root or "") .. "`",
    string.format("- Repos: `%d`", #group.repos),
    string.format("- Dirty repos: `%d`", group.dirty or 0),
    string.format("- Ahead / Behind: `%d / %d`", group.ahead or 0, group.behind or 0),
    "",
    "## Repositories",
  }
  for _, repo in ipairs(group.repos or {}) do
    lines[#lines + 1] = string.format("- `%s`  [%s]  %s", repo.name, repo.track or "=", repo.status or "干净")
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Actions"
  lines[#lines + 1] = "- <CR> 查看该 branch 分组下的 repos"
  lines[#lines + 1] = "- <C-p> 批量 pull --ff-only"
  lines[#lines + 1] = "- <C-u> 批量 fetch --all --prune"
  return lines
end

function M.repo(repo)
  if not repo then return { "No preview" } end
  local commit = repo.last_commit or {}
  return {
    "# " .. repo.name,
    "",
    "- Workspace: `" .. (repo.workspace_root or "") .. "`",
    "- Repo Root: `" .. repo.root .. "`",
    "- Branch: `" .. (repo.branch or "(unknown)") .. "`",
    "- Track: `" .. (repo.upstream or "-") .. "  " .. (repo.track or "=") .. "`",
    "- Status: " .. repo.status,
    "",
    "## Last Commit",
    string.format("- `%s` %s", commit.hash or "-", commit.subject or "No commits yet"),
    string.format("- %s · %s", commit.reltime or "-", commit.author or "-"),
    "",
    "## Actions",
    "- <CR> 进入该仓库的 branches 面板",
    "- <C-s> 打开 status picker",
    "- <C-h> 打开 log picker",
    "- <C-f> 打开 git files",
    "- <C-n> 打开 Neogit",
    "- <C-g> 打开 LazyGit",
  }
end

function M.branch(item)
  if not item then return { "No preview" } end
  local lines = util.git_lines(item.root, { "log", "-1", "--pretty=format:%h\t%an\t%cr\t%s", item.branch }) or {}
  local hash, author, reltime, subject = nil, nil, nil, nil
  if lines[1] then
    hash, author, reltime, subject = unpack(vim.split(lines[1], "\t", { plain = true }))
  end
  local current = item.current and "yes" or "no"
  return {
    "# " .. item.branch,
    "",
    "- Repo: `" .. item.repo .. "`",
    "- Root: `" .. item.root .. "`",
    "- Current: `" .. current .. "`",
    "- Upstream: `" .. (item.upstream or "-") .. "`",
    "- Track: `" .. (item.track or "=") .. "`",
    "- Updated: `" .. (item.reltime or "-") .. "`",
    "",
    "## Last Commit",
    string.format("- `%s` %s", hash or "-", subject or "No commits yet"),
    string.format("- %s · %s", reltime or "-", author or "-"),
    "",
    "## Actions",
    "- <CR> checkout/switch 到该 branch",
    "- <C-s> 打开该 repo 的 status picker",
    "- <C-h> 打开该 repo 的 log picker",
    "- <C-n> 打开该 repo 的 Neogit",
    "- <C-g> 打开该 repo 的 LazyGit",
  }
end

return M
