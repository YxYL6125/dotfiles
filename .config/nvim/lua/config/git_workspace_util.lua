local M = {}

local uv = vim.uv or vim.loop
local sep = package.config:sub(1, 1)

function M.notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Git Workspace" })
end

function M.normalize(path)
  if not path or path == "" then return nil end
  local normalized = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  if normalized:sub(-1) == sep and normalized ~= sep then normalized = normalized:sub(1, -2) end
  return normalized
end

function M.path_join(...)
  return M.normalize(table.concat({ ... }, sep))
end

function M.is_dir(path)
  local stat = path and uv.fs_stat(path) or nil
  return stat and stat.type == "directory" or false
end

function M.shellescape(path)
  return vim.fn.shellescape(path)
end

function M.system(cmd, opts)
  opts = opts or {}
  local result = vim.system(cmd, {
    cwd = opts.cwd,
    text = true,
  }):wait()
  if result.code ~= 0 then return nil, result end
  local stdout = vim.trim(result.stdout or "")
  if stdout == "" then return {}, result end
  return vim.split(stdout, "\n", { plain = true, trimempty = true }), result
end

function M.git_lines(root, args)
  if not root or root == "" then return nil end
  local cmd = vim.list_extend({ "git" }, args)
  return M.system(cmd, { cwd = root })
end

function M.git_root(path)
  local dir = M.normalize(path)
  if not dir then return nil end
  local lines = M.git_lines(dir, { "rev-parse", "--show-toplevel" })
  return lines and M.normalize(lines[1]) or nil
end

function M.get_snacks()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.picker and snacks.picker.select then return snacks end
end

local function preview_payload(item)
  return item and (item.item or item) or nil
end

local function set_preview_lines(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "markdown"
end

function M.picker_select(items, opts, on_choice)
  opts = opts or {}
  local snacks = M.get_snacks()
  if snacks then
    local actions = vim.tbl_extend("force", {}, opts.actions or {})
    local keymaps = opts.keys or {}
    return snacks.picker.select(items, {
      prompt = opts.prompt,
      format_item = opts.format_item,
      snacks = {
        preview = opts.preview and function(ctx)
          set_preview_lines(ctx.buf, opts.preview(preview_payload(ctx.item)))
        end or nil,
        layout = { preset = "select" },
        actions = actions,
        win = {
          input = { keys = keymaps },
          list = { keys = keymaps },
        },
      },
    }, on_choice)
  end

  return vim.ui.select(items, {
    prompt = opts.prompt,
    format_item = opts.format_item,
  }, on_choice)
end

return M
