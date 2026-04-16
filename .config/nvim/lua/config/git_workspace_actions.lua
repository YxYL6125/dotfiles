local util = require "config.git_workspace_util"

local M = {}

function M.with_entry(item)
  return item and (item.item or item) or nil
end

function M.open_lazygit(root)
  local astro = require "astrocore"
  astro.toggle_term_cmd {
    cmd = "cd " .. util.shellescape(root) .. " && lazygit",
    direction = "float",
  }
end

function M.open_batch_terminal(title, shell_lines)
  local astro = require "astrocore"
  astro.toggle_term_cmd {
    cmd = "/bin/bash -lc " .. util.shellescape(table.concat(shell_lines, "\n")),
    direction = "float",
  }
  util.notify(title)
end

function M.open_neogit(root, popup)
  require("lazy").load { plugins = { "neogit" } }
  local opts = { cwd = root, kind = "floating" }
  if popup then opts[1] = popup end
  require("neogit").open(opts)
end

function M.open_snacks_picker(method, root)
  local snacks = util.get_snacks()
  if not snacks then
    util.notify("snacks.nvim 不可用", vim.log.levels.ERROR)
    return
  end
  snacks.picker[method] { cwd = root }
end

function M.checkout_branch(item)
  local entry = M.with_entry(item)
  if not entry then return end
  if entry.current then
    util.notify("已经在 branch: " .. entry.branch)
    return
  end
  local _, result = util.system({ "git", "switch", entry.branch }, { cwd = entry.root })
  if not result or result.code ~= 0 then
    util.notify(vim.trim((result and result.stderr) or "切换分支失败"), vim.log.levels.ERROR)
    return
  end
  util.notify(string.format("已切换 %s -> %s", entry.repo, entry.branch))
end

function M.run_group_git_command(group, args, label)
  if not group or not group.repos or #group.repos == 0 then
    util.notify("这个 branch 分组下没有仓库", vim.log.levels.WARN)
    return
  end
  local shell_lines = {
    "set -u",
    "printf 'Git Workspace Batch: %s\\nBranch: %s\\n\\n' " .. util.shellescape(label) .. " " .. util.shellescape(group.branch),
  }
  for _, repo in ipairs(group.repos) do
    shell_lines[#shell_lines + 1] = "printf '=== %s ===\\n' " .. util.shellescape(repo.name)
    shell_lines[#shell_lines + 1] = "git -C " .. util.shellescape(repo.root) .. " " .. table.concat(args, " ") .. " || true"
    shell_lines[#shell_lines + 1] = "printf '\\n'"
  end
  M.open_batch_terminal("Git Workspace: " .. label .. " › " .. group.branch, shell_lines)
end

return M
