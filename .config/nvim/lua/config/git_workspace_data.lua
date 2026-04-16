local util = require "config.git_workspace_util"

local M = {}

local ignored_dirs = {
  [".git"] = true,
  [".idea"] = true,
  ["node_modules"] = true,
  ["target"] = true,
  ["build"] = true,
  ["dist"] = true,
  ["tmp"] = true,
  ["temp"] = true,
  ["vendor"] = true,
  ["kitex_gen"] = true,
  ["thrift_gen"] = true,
  ["gen"] = true,
  ["generated"] = true,
}

local function is_git_repo(path)
  return util.git_root(path) ~= nil
end

local function list_child_dirs(root)
  local dirs = {}
  local handle = root and (vim.uv or vim.loop).fs_scandir(root) or nil
  if not handle then return dirs end
  while true do
    local name, kind = (vim.uv or vim.loop).fs_scandir_next(handle)
    if not name then break end
    if kind == "directory" and not ignored_dirs[name] and name:sub(1, 1) ~= "." then dirs[#dirs + 1] = name end
  end
  table.sort(dirs)
  return dirs
end

local function repo_candidates(root)
  local repos = {}
  for _, name in ipairs(list_child_dirs(root)) do
    local repo_root = util.path_join(root, name)
    if is_git_repo(repo_root) then repos[#repos + 1] = { name = name, root = repo_root } end
  end
  return repos
end

local function parse_branch_header(line)
  local info = {
    head = "(unknown)",
    upstream = nil,
    ahead = 0,
    behind = 0,
    gone = false,
    detached = false,
  }
  local body = (line or ""):gsub("^##%s*", "")
  if body == "" then return info end

  local track = body:match("%[(.-)%]$")
  if track then body = vim.trim(body:gsub("%s*%[.-%]$", "")) end

  local head, upstream = body:match("^(.-)%.%.%.(.+)$")
  if head then
    info.head = head
    info.upstream = upstream
  else
    info.head = body
  end

  if info.head:match("^HEAD %(.*%)$") then info.detached = true end
  if info.head:match("^No commits yet on ") then info.head = info.head:gsub("^No commits yet on ", "") end
  if track then
    info.ahead = tonumber(track:match("ahead (%d+)")) or 0
    info.behind = tonumber(track:match("behind (%d+)")) or 0
    info.gone = track:match("gone") ~= nil
  end
  return info
end

local function parse_status_counts(lines)
  local counts = { staged = 0, unstaged = 0, untracked = 0, conflicts = 0 }
  for i = 2, #lines do
    local code = lines[i]:sub(1, 2)
    if code == "??" then
      counts.untracked = counts.untracked + 1
    elseif code:find("U") or code == "AA" or code == "DD" then
      counts.conflicts = counts.conflicts + 1
    else
      local x, y = code:sub(1, 1), code:sub(2, 2)
      if x ~= " " and x ~= "?" and x ~= "!" then counts.staged = counts.staged + 1 end
      if y ~= " " and y ~= "?" and y ~= "!" then counts.unstaged = counts.unstaged + 1 end
    end
  end
  return counts
end

local function status_summary_text(repo)
  local parts = {}
  if repo.conflicts > 0 then parts[#parts + 1] = "冲突:" .. repo.conflicts end
  if repo.staged > 0 then parts[#parts + 1] = "暂存:" .. repo.staged end
  if repo.unstaged > 0 then parts[#parts + 1] = "改动:" .. repo.unstaged end
  if repo.untracked > 0 then parts[#parts + 1] = "未跟踪:" .. repo.untracked end
  if #parts == 0 then parts[#parts + 1] = "干净" end
  return table.concat(parts, "  ")
end

local function ahead_behind_text(repo)
  local parts = {}
  if repo.gone then parts[#parts + 1] = "upstream gone" end
  if repo.ahead > 0 then parts[#parts + 1] = "↑" .. repo.ahead end
  if repo.behind > 0 then parts[#parts + 1] = "↓" .. repo.behind end
  return #parts > 0 and table.concat(parts, " ") or "="
end

local function enrich_repo(repo)
  local lines = util.git_lines(repo.root, { "status", "--short", "--branch", "--untracked-files=normal" }) or {}
  local branch = parse_branch_header(lines[1])
  local counts = parse_status_counts(lines)
  local log = util.git_lines(repo.root, { "log", "-1", "--pretty=format:%h\t%s\t%cr\t%an" }) or {}
  local hash, subject, reltime, author = nil, nil, nil, nil
  if log[1] then
    hash, subject, reltime, author = unpack(vim.split(log[1], "\t", { plain = true }))
  end

  repo.branch = branch.head
  repo.upstream = branch.upstream
  repo.ahead = branch.ahead
  repo.behind = branch.behind
  repo.gone = branch.gone
  repo.detached = branch.detached
  repo.staged = counts.staged
  repo.unstaged = counts.unstaged
  repo.untracked = counts.untracked
  repo.conflicts = counts.conflicts
  repo.status = status_summary_text(repo)
  repo.track = ahead_behind_text(repo)
  repo.last_commit = {
    hash = hash,
    subject = subject,
    reltime = reltime,
    author = author,
  }
  return repo
end

local function ancestor_chain(path, max_depth)
  local chain, seen = {}, {}
  local dir = util.normalize(path)
  local home = util.normalize((vim.uv or vim.loop).os_homedir())
  local depth = 0
  while dir and dir ~= "" and not seen[dir] do
    chain[#chain + 1] = dir
    seen[dir] = true
    if dir == home or depth >= (max_depth or 8) then break end
    local parent = util.normalize(vim.fs.dirname(dir))
    if not parent or parent == dir then break end
    dir = parent
    depth = depth + 1
  end
  return chain
end

local function workspace_seeds(explicit_path)
  local seeds, seen = {}, {}
  local function add(path)
    path = util.normalize(path)
    if path and not seen[path] then
      seeds[#seeds + 1] = path
      seen[path] = true
    end
  end

  add(explicit_path)
  add(vim.fn.getcwd())

  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" then add(vim.fn.fnamemodify(file, ":p:h")) end

  local cwd_git = util.git_root(vim.fn.getcwd())
  if cwd_git then add(vim.fs.dirname(cwd_git)) end

  if file ~= "" then
    local file_git = util.git_root(vim.fn.fnamemodify(file, ":p:h"))
    if file_git then add(vim.fs.dirname(file_git)) end
  end

  return seeds
end

function M.detect_workspace(explicit_path)
  local best = nil
  for _, seed in ipairs(workspace_seeds(explicit_path)) do
    for _, dir in ipairs(ancestor_chain(seed, 8)) do
      local repos = repo_candidates(dir)
      if #repos >= 2 then return { root = dir, repos = repos } end
      if #repos > 0 and (not best or #repos > #best.repos) then best = { root = dir, repos = repos } end
    end
  end

  if best then return best end

  local fallback = util.normalize(explicit_path or vim.fn.getcwd())
  if is_git_repo(fallback) then
    return {
      root = fallback,
      repos = { { name = vim.fs.basename(fallback), root = fallback } },
    }
  end

  return { root = fallback, repos = {} }
end

function M.collect_repos(explicit_path)
  local ctx = M.detect_workspace(explicit_path)
  local items = {}
  for _, repo in ipairs(ctx.repos) do
    local item = enrich_repo(vim.deepcopy(repo))
    item.workspace_root = ctx.root
    items[#items + 1] = item
  end
  table.sort(items, function(a, b)
    local a_dirty = (a.conflicts + a.staged + a.unstaged + a.untracked) > 0
    local b_dirty = (b.conflicts + b.staged + b.unstaged + b.untracked) > 0
    if a_dirty ~= b_dirty then return a_dirty end
    return a.name < b.name
  end)
  return ctx, items
end

function M.collect_branch_groups(explicit_path)
  local ctx, repos = M.collect_repos(explicit_path)
  local groups, ordered = {}, {}
  for _, repo in ipairs(repos) do
    local key = repo.branch or "(unknown)"
    if not groups[key] then
      groups[key] = {
        branch = key,
        workspace_root = ctx.root,
        repos = {},
        repo_names = {},
        dirty = 0,
        ahead = 0,
        behind = 0,
        current = false,
      }
      ordered[#ordered + 1] = groups[key]
    end
    local group = groups[key]
    group.repos[#group.repos + 1] = repo
    group.repo_names[#group.repo_names + 1] = repo.name
    if (repo.conflicts + repo.staged + repo.unstaged + repo.untracked) > 0 then group.dirty = group.dirty + 1 end
    if repo.ahead and repo.ahead > 0 then group.ahead = group.ahead + repo.ahead end
    if repo.behind and repo.behind > 0 then group.behind = group.behind + repo.behind end
    if repo.current then group.current = true end
  end
  table.sort(ordered, function(a, b)
    if a.current ~= b.current then return a.current end
    if #a.repos ~= #b.repos then return #a.repos > #b.repos end
    return a.branch < b.branch
  end)
  for _, group in ipairs(ordered) do
    table.sort(group.repos, function(a, b) return a.name < b.name end)
    table.sort(group.repo_names)
  end
  return ctx, ordered
end

function M.collect_branches(explicit_path, opts)
  opts = opts or {}
  local ctx, repos = M.collect_repos(explicit_path)
  local items = {}
  for _, repo in ipairs(repos) do
    if not opts.repo or repo.name == opts.repo then
      local lines = util.git_lines(repo.root, {
        "for-each-ref",
        "--sort=-committerdate",
        "--format=%(HEAD)%09%(refname:short)%09%(upstream:short)%09%(upstream:trackshort)%09%(committerdate:relative)%09%(contents:subject)",
        "refs/heads",
      }) or {}
      for _, line in ipairs(lines) do
        local parts = vim.split(line, "\t", { plain = true })
        items[#items + 1] = {
          workspace_root = ctx.root,
          repo = repo.name,
          root = repo.root,
          branch = parts[2] or "",
          current = (parts[1] or "") == "*",
          upstream = parts[3] ~= "" and parts[3] or nil,
          track = parts[4] ~= "" and parts[4] or nil,
          reltime = parts[5] or "",
          subject = parts[6] or "",
        }
      end
    end
  end
  table.sort(items, function(a, b)
    if a.current ~= b.current then return a.current end
    if a.repo ~= b.repo then return a.repo < b.repo end
    return a.branch < b.branch
  end)
  return ctx, items
end

return M
