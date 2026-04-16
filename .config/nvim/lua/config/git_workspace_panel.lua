local util = require "config.git_workspace_util"
local data = require "config.git_workspace_data"
local actions = require "config.git_workspace_actions"
local pickers = require "config.git_workspace_pickers"

local M = {}

local SORT_NEXT = {
  current_size = "branch",
  branch = "dirty",
  dirty = "current_size",
}

local DEFAULT_FILTERS = {
  dirty_only = false,
  track_only = false,
  sort_mode = "current_size",
}

local state = {
  left_buf = nil,
  right_buf = nil,
  left_win = nil,
  right_win = nil,
  groups = {},
  visible_groups = {},
  group_index = 1,
  repo_index = 1,
  focus = "left",
  filters = vim.deepcopy(DEFAULT_FILTERS),
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function reset_filters()
  state.filters = vim.deepcopy(DEFAULT_FILTERS)
end

local function reset_selection()
  state.group_index = 1
  state.repo_index = 1
  state.focus = "left"
end

local function current_group()
  return state.visible_groups[state.group_index]
end

local function current_repo()
  local group = current_group()
  return group and group.repos and group.repos[state.repo_index] or nil
end

local function group_sorter(a, b)
  local mode = state.filters.sort_mode
  if mode == "branch" then return a.branch < b.branch end
  if mode == "dirty" then
    if (a.dirty or 0) ~= (b.dirty or 0) then return (a.dirty or 0) > (b.dirty or 0) end
    return a.branch < b.branch
  end
  if a.current ~= b.current then return a.current end
  if #a.repos ~= #b.repos then return #a.repos > #b.repos end
  return a.branch < b.branch
end

local function apply_filters(groups)
  local filtered = vim.deepcopy(groups)
  if state.filters.dirty_only then
    filtered = vim.tbl_filter(function(group) return (group.dirty or 0) > 0 end, filtered)
  end
  if state.filters.track_only then
    filtered = vim.tbl_filter(function(group) return (group.ahead or 0) > 0 or (group.behind or 0) > 0 end, filtered)
  end
  table.sort(filtered, group_sorter)
  return filtered
end

local function statusline()
  local filters = {
    state.filters.dirty_only and "dirty" or "all",
    state.filters.track_only and "tracked" or "any-track",
    "sort:" .. state.filters.sort_mode,
  }
  return string.format("Filters: %s", table.concat(filters, " · "))
end

local function left_lines()
  local lines = { statusline(), "" }
  for idx, group in ipairs(state.visible_groups) do
    local marker = idx == state.group_index and "▶" or " "
    local dirty = (group.dirty or 0) > 0 and (" dirty:" .. group.dirty) or ""
    local track = ((group.ahead or 0) > 0 and (" ↑" .. group.ahead) or "") .. ((group.behind or 0) > 0 and (" ↓" .. group.behind) or "")
    lines[#lines + 1] = string.format("%s %-28s [%2d repos]%s%s", marker, group.branch, #group.repos, dirty, track)
  end
  if #state.visible_groups == 0 then return { statusline(), "", "No branch groups" } end
  return lines
end

local function right_lines()
  local lines = { statusline(), "" }
  local group = current_group()
  if not group then return { statusline(), "", "No branch group selected" } end

  lines[#lines + 1] = string.format("Branch: %s", group.branch)
  lines[#lines + 1] = string.format("Repos: %d", #group.repos)
  lines[#lines + 1] = ""
  for idx, repo in ipairs(group.repos) do
    local marker = idx == state.repo_index and "▶" or " "
    lines[#lines + 1] = string.format("%s %-24s %-8s %s", marker, repo.name, repo.track or "=", repo.status or "干净")
  end
  if #group.repos == 0 then lines[#lines + 1] = "No repos in this branch group" end
  return lines
end

local function normalize_selection()
  state.group_index = math.max(1, math.min(#state.visible_groups > 0 and #state.visible_groups or 1, state.group_index))
  local group = current_group()
  local repo_count = group and #group.repos or 0
  state.repo_index = math.max(1, math.min(math.max(repo_count, 1), state.repo_index))
end

local function close_panel()
  for _, win in ipairs { state.left_win, state.right_win } do
    if valid_win(win) then pcall(vim.api.nvim_win_close, win, true) end
  end
  state.left_win = nil
  state.right_win = nil
  state.left_buf = nil
  state.right_buf = nil
  state.groups = {}
  state.visible_groups = {}
  reset_selection()
  reset_filters()
end

local function render()
  if not valid_buf(state.left_buf) or not valid_buf(state.right_buf) then return end

  state.visible_groups = apply_filters(state.groups)
  normalize_selection()

  local left = left_lines()
  local right = right_lines()
  local group = current_group()

  vim.bo[state.left_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.left_buf, 0, -1, false, left)
  vim.bo[state.left_buf].modifiable = false
  vim.bo[state.right_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.right_buf, 0, -1, false, right)
  vim.bo[state.right_buf].modifiable = false

  if valid_win(state.left_win) then
    local left_line = #state.visible_groups == 0 and 3 or (2 + state.group_index)
    vim.api.nvim_win_set_cursor(state.left_win, { left_line, 0 })
  end
  if valid_win(state.right_win) then
    local repo_line = group and (5 + state.repo_index) or 1
    vim.api.nvim_win_set_cursor(state.right_win, { math.max(1, math.min(repo_line, #right)), 0 })
  end
end

local function focus(which)
  state.focus = which
  local win = which == "left" and state.left_win or state.right_win
  if valid_win(win) then vim.api.nvim_set_current_win(win) end
end

local function move(delta)
  if state.focus == "left" then
    state.group_index = state.group_index + delta
  else
    state.repo_index = state.repo_index + delta
  end
  render()
end

local function toggle_focus()
  focus(state.focus == "left" and "right" or "left")
end

local function update_filter(key)
  state.filters[key] = not state.filters[key]
  reset_selection()
  render()
end

local function cycle_sort()
  state.filters.sort_mode = SORT_NEXT[state.filters.sort_mode] or DEFAULT_FILTERS.sort_mode
  render()
end

local function batch_pull()
  local group = current_group()
  if group then actions.run_group_git_command(group, { "pull", "--ff-only" }, "batch pull --ff-only") end
end

local function batch_fetch()
  local group = current_group()
  if group then actions.run_group_git_command(group, { "fetch", "--all", "--prune" }, "batch fetch --all --prune") end
end

local function repo_action(method)
  local repo = current_repo()
  if not repo then return end
  if method == "branches" then
    close_panel()
    pickers.repo_branches(repo)
  elseif method == "status" then
    actions.open_snacks_picker("git_status", repo.root)
  elseif method == "log" then
    actions.open_snacks_picker("git_log", repo.root)
  elseif method == "files" then
    actions.open_snacks_picker("git_files", repo.root)
  elseif method == "neogit" then
    actions.open_neogit(repo.root)
  elseif method == "lazygit" then
    actions.open_lazygit(repo.root)
  end
end

local function map(buf, lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = desc })
end

local function map_common(buf)
  map(buf, "q", close_panel, "Close Git workspace panel")
  map(buf, "<Esc>", close_panel, "Close Git workspace panel")
  map(buf, "j", function() move(1) end, "Move down")
  map(buf, "k", function() move(-1) end, "Move up")
  map(buf, "<Down>", function() move(1) end, "Move down")
  map(buf, "<Up>", function() move(-1) end, "Move up")
  map(buf, "<Tab>", toggle_focus, "Toggle pane focus")
  map(buf, "/", cycle_sort, "Cycle sort mode")
  map(buf, "d", function() update_filter "dirty_only" end, "Toggle dirty-only filter")
  map(buf, "t", function() update_filter "track_only" end, "Toggle ahead/behind filter")
  map(buf, "<C-p>", batch_pull, "Batch pull selected branch group")
  map(buf, "<C-u>", batch_fetch, "Batch fetch selected branch group")
end

function M.workspace_panel(explicit_path)
  local ctx, groups = data.collect_branch_groups(explicit_path)
  if #groups == 0 then
    util.notify("当前路径附近没找到多仓库工作区: " .. (ctx.root or vim.fn.getcwd()), vim.log.levels.WARN)
    return
  end

  close_panel()
  state.groups = groups
  state.visible_groups = groups
  reset_selection()

  state.left_buf = vim.api.nvim_create_buf(false, true)
  state.right_buf = vim.api.nvim_create_buf(false, true)
  for _, buf in ipairs { state.left_buf, state.right_buf } do
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "gitworkspace"
  end

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.75)
  local row = math.floor((vim.o.lines - height) / 2 - 1)
  local col = math.floor((vim.o.columns - width) / 2)
  local left_width = math.floor(width * 0.42)
  local right_width = width - left_width - 1

  state.left_win = vim.api.nvim_open_win(state.left_buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = left_width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Git Branch Groups ",
    title_pos = "center",
  })
  state.right_win = vim.api.nvim_open_win(state.right_buf, false, {
    relative = "editor",
    row = row,
    col = col + left_width + 1,
    width = right_width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Branch Repos ",
    title_pos = "center",
  })

  map_common(state.left_buf)
  map_common(state.right_buf)
  map(state.left_buf, "<CR>", function() focus("right") end, "Focus branch repos")
  map(state.right_buf, "<CR>", function() repo_action("branches") end, "Open repo branches")
  map(state.right_buf, "s", function() repo_action("status") end, "Open repo status")
  map(state.right_buf, "h", function() repo_action("log") end, "Open repo log")
  map(state.right_buf, "f", function() repo_action("files") end, "Open repo files")
  map(state.right_buf, "n", function() repo_action("neogit") end, "Open repo neogit")
  map(state.right_buf, "g", function() repo_action("lazygit") end, "Open repo lazygit")

  render()
  focus("left")
end

return M
