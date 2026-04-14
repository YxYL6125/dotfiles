local command_candidates = { "cloudide-cli", "clouddev", "cloud-dev" }

local state = {
  selected_env = nil,
}

local function detect_command()
  for _, candidate in ipairs(command_candidates) do
    if vim.fn.executable(candidate) == 1 then return candidate end
  end
end

local function set_selected_env(env)
  if env == nil then
    state.selected_env = nil
    return
  end

  state.selected_env = {
    id = env.id,
    label = env.label,
  }
end

local function ensure_selected_env_still_exists(envs)
  if not state.selected_env then return end

  for _, env in ipairs(envs) do
    if env.id == state.selected_env.id then return end
  end

  set_selected_env(nil)
end

---@class CloudDevEnv
---@field id string
---@field label string
---@field status string|nil
---@field repo_hint string|nil
---@field repositories string[]|nil

---@class CloudDevBinding
---@field workspace_id string
---@field workspace_label string|nil
---@field repo_hint string|nil
---@field updated_at string

local cloudide_tenant_name = "bytedance"
local cloudide_api_server_base_url = "https://ide.byted.org"
local bindings_file = vim.fs.joinpath(vim.fn.stdpath "data", "clouddev", "workspace_bindings.json")

local function now_iso8601()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function current_buffer_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then return vim.uv.cwd() end
  return vim.fs.dirname(name)
end

local function find_git_root()
  local start = current_buffer_dir()
  local git_dir = vim.fs.find(".git", { upward = true, path = start, type = "directory" })[1]
  if git_dir then return vim.fs.dirname(git_dir) end
  local git_file = vim.fs.find(".git", { upward = true, path = start, type = "file" })[1]
  if git_file then return vim.fs.dirname(git_file) end
end

local function run_system_sync(cmd, args)
  return vim.system(vim.list_extend({ cmd }, args), { text = true }):wait()
end

local function git_remote_url(root)
  if not root then return nil end
  local result = run_system_sync("git", { "-C", root, "remote", "get-url", "origin" })
  if result.code ~= 0 then return nil end
  local url = vim.trim(result.stdout or "")
  return url ~= "" and url or nil
end

local function ensure_bindings_parent_dir()
  vim.fn.mkdir(vim.fs.dirname(bindings_file), "p")
end

local function load_bindings()
  local fd = vim.uv.fs_open(bindings_file, "r", 420)
  if not fd then return {} end

  local stat = vim.uv.fs_fstat(fd)
  local data = stat and vim.uv.fs_read(fd, stat.size, 0) or nil
  vim.uv.fs_close(fd)

  local ok, decoded = pcall(vim.json.decode, data or "{}")
  if not ok or type(decoded) ~= "table" then return {} end

  return decoded
end

local function save_bindings(bindings)
  ensure_bindings_parent_dir()

  local fd = assert(vim.uv.fs_open(bindings_file, "w", 420))
  vim.uv.fs_write(fd, vim.json.encode(bindings), 0)
  vim.uv.fs_close(fd)
end

local function get_binding(project_root)
  if not project_root then return nil end
  return load_bindings()[project_root]
end

local function set_binding(project_root, env)
  if not project_root then return end

  local bindings = load_bindings()
  bindings[project_root] = {
    workspace_id = env.id,
    workspace_label = env.label,
    repo_hint = env.repo_hint,
    updated_at = now_iso8601(),
  }
  save_bindings(bindings)
end

local function clear_binding(project_root)
  if not project_root then return end

  local bindings = load_bindings()
  bindings[project_root] = nil
  save_bindings(bindings)
end

local function repo_name_from_remote(url)
  if not url or url == "" then return nil end
  local tail = url:gsub("%.git$", ""):match("([^/:]+)$")
  return tail
end

local function parse_repositories(item)
  local raw_repositories = item.Repositories
  if type(raw_repositories) == "string" then
    local ok, decoded = pcall(vim.json.decode, raw_repositories)
    raw_repositories = ok and decoded or nil
  end

  if type(raw_repositories) ~= "table" or vim.islist(raw_repositories) ~= true then return nil end

  local repos = {}
  for _, repo in ipairs(raw_repositories) do
    if type(repo) == "string" then repos[#repos + 1] = repo end
  end

  return vim.tbl_isempty(repos) and nil or repos
end

local function parse_envs(raw)
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" or vim.islist(decoded) ~= true then return nil end

  local envs = {}
  for _, item in ipairs(decoded) do
    if type(item) == "table" and type(item.ID) == "string" then
      envs[#envs + 1] = {
        id = item.ID,
        label = item.Name or item.ExternalID or item.ID,
        status = item.State,
        repo_hint = type(item.ExternalID) == "string" and item.ExternalID or nil,
        repositories = parse_repositories(item),
      }
    end
  end

  return envs
end

local function project_context()
  local root = find_git_root()
  local remote = git_remote_url(root)
  local repo_name = repo_name_from_remote(remote) or (root and vim.fs.basename(root) or nil)

  return {
    root = root,
    remote = remote,
    repo_name = repo_name,
  }
end

local function env_match_score(env, ctx)
  if not ctx.repo_name then return 0 end

  local repo_name = ctx.repo_name:lower()
  local score = 0

  if type(env.repo_hint) == "string" then
    local repo_hint = env.repo_hint:lower()
    if repo_hint == repo_name then
      score = score + 100
    elseif repo_hint:find(repo_name, 1, true) then
      score = score + 80
    end
  end

  if type(env.label) == "string" then
    local label = env.label:lower()
    if label == repo_name then
      score = score + 60
    elseif label:find(repo_name, 1, true) then
      score = score + 40
    end
  end

  if env.repositories then
    for _, repo in ipairs(env.repositories) do
      local repo_value = repo:lower()
      if repo_value == repo_name then
        score = score + 90
      elseif repo_value:find(repo_name, 1, true) then
        score = score + 80
      end
    end
  end

  return score
end

local function find_candidate_envs(envs, ctx)
  local candidates = {}

  for _, env in ipairs(envs) do
    local score = env_match_score(env, ctx)
    if score > 0 then candidates[#candidates + 1] = { env = env, score = score } end
  end

  table.sort(candidates, function(a, b)
    if a.score == b.score then return a.env.label < b.env.label end
    return a.score > b.score
  end)

  return candidates
end

local function env_by_id(envs, id)
  for _, env in ipairs(envs) do
    if env.id == id then return env end
  end
end

local function resolve_bound_env(envs, ctx)
  if not ctx.root then return nil end

  local binding = get_binding(ctx.root)
  if not binding then return nil end

  local env = env_by_id(envs, binding.workspace_id)
  if env then return env, "binding" end

  clear_binding(ctx.root)
end

local function prompt_for_env(envs, prompt, on_choice)
  vim.ui.select(envs, {
    prompt = prompt,
    format_item = function(env)
      if env.status and env.status ~= "" then
        return ("%s [%s] (%s)"):format(env.label, env.id, env.status)
      end
      return ("%s [%s]"):format(env.label, env.id)
    end,
  }, on_choice)
end

local function resolve_project_env(envs, ctx, callback)
  local bound, source = resolve_bound_env(envs, ctx)
  if bound then
    callback(bound, source)
    return
  end

  local candidates = find_candidate_envs(envs, ctx)
  if #candidates == 1 then
    callback(candidates[1].env, "auto")
    return
  end

  if #candidates > 1 then
    local options = vim.tbl_map(function(item) return item.env end, candidates)
    prompt_for_env(options, "Select Cloud Dev workspace for project", function(choice)
      if not choice then return end
      if ctx.root then set_binding(ctx.root, choice) end
      callback(choice, "prompt")
    end)
    return
  end

  prompt_for_env(envs, "No workspace matched automatically. Select one", function(choice)
    if not choice then return end
    if ctx.root then set_binding(ctx.root, choice) end
    callback(choice, "manual")
  end)
end

local function run_system(cmd, args, callback)
  vim.system(vim.list_extend({ cmd }, args), { text = true }, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

local function shellescape_arg(arg)
  return vim.fn.shellescape(tostring(arg))
end

---@class CloudDevStatusSummary
---@field cli_available boolean
---@field command string|nil
---@field selected_env { id: string, label: string }|nil
---@field auth_hint string|nil
local function status_summary()
  local command = detect_command()

  return {
    cli_available = command ~= nil,
    command = command,
    selected_env = state.selected_env,
    auth_hint = command and nil or string.format("Cloud Dev CLI not found. Checked: %s", table.concat(command_candidates, ", ")),
  }
end

local function render_status(summary)
  local lines = {}

  lines[#lines + 1] = summary.cli_available
      and ("Cloud Dev CLI: " .. summary.command)
      or "Cloud Dev CLI: unavailable"

  if summary.selected_env then
    lines[#lines + 1] = ("Current environment: %s (%s)"):format(summary.selected_env.label, summary.selected_env.id)
  else
    lines[#lines + 1] = "Current environment: none"
  end

  if summary.auth_hint then lines[#lines + 1] = summary.auth_hint end

  vim.notify(table.concat(lines, "\n"), summary.cli_available and vim.log.levels.INFO or vim.log.levels.WARN, {
    title = "Cloud Dev",
  })
end

local function open_floating_terminal(cmdline)
  vim.cmd "ToggleTerm direction=float"
  local escaped = vim.fn.fnameescape(cmdline)
  vim.cmd("TermExec direction=float cmd='" .. escaped:gsub("'", [['"'"']]) .. "'")
end

local function format_command_for_display(cmd, args)
  local parts = vim.tbl_map(shellescape_arg, vim.list_extend({ cmd }, args))
  return table.concat(parts, " ")
end

local function command_error_message(action, cmd, args, result)
  local details = vim.trim(result.stderr or "")
  if details == "" then details = vim.trim(result.stdout or "") end
  if details == "" then details = "Exit code: " .. tostring(result.code) end

  return string.format("%s\nCommand: %s\n%s", action, format_command_for_display(cmd, args), details)
end

local function list_command(cmd)
  return table.concat({
    cmd,
    "workspace",
    "list",
    "--tenant-name",
    cloudide_tenant_name,
    "--apiserver-baseurl",
    cloudide_api_server_base_url,
  }, " ")
end

local function enter_args(env)
  return {
    "workspace",
    "ssh",
    "connect",
    "--id",
    env.id,
    "--tenant-name",
    cloudide_tenant_name,
    "--apiserver-baseurl",
    cloudide_api_server_base_url,
  }
end

local function enter_command(cmd, env)
  return format_command_for_display(cmd, enter_args(env))
end

local function get_envs(callback)
  local cmd = detect_command()
  if not cmd then
    vim.notify("Cloud Dev CLI not found", vim.log.levels.ERROR)
    return
  end

  local args = {
    "workspace",
    "list",
    "--output=json",
    "--tenant-name",
    cloudide_tenant_name,
    "--apiserver-baseurl",
    cloudide_api_server_base_url,
  }

  run_system(cmd, args, function(result)
    if result.code ~= 0 then
      vim.notify(command_error_message("Failed to load Cloud Dev environments", cmd, args, result), vim.log.levels.ERROR)
      return
    end

    local envs = parse_envs(result.stdout)
    if not envs or vim.tbl_isempty(envs) then
      vim.notify("No Cloud Dev environments found", vim.log.levels.WARN)
      return
    end

    ensure_selected_env_still_exists(envs)
    callback(cmd, envs)
  end)
end

local function start_args(env)
  return {
    "workspace",
    "modify",
    env.id,
    "--operation",
    "start",
    "--tenant-name",
    cloudide_tenant_name,
    "--apiserver-baseurl",
    cloudide_api_server_base_url,
    "--wait",
  }
end

local function attach_env(cmd, env)
  vim.notify(("Attaching to Cloud Dev environment: %s (%s)"):format(env.label, env.id), vim.log.levels.INFO)

  if env.status == "started" then
    open_floating_terminal(enter_command(cmd, env))
    return
  end

  local args = start_args(env)
  vim.notify(("Starting Cloud Dev environment: %s (%s)"):format(env.label, env.id), vim.log.levels.INFO)
  run_system(cmd, args, function(result)
    if result.code ~= 0 then
      vim.notify(command_error_message("Failed to start Cloud Dev environment", cmd, args, result), vim.log.levels.ERROR)
      return
    end

    vim.notify(("Cloud Dev environment started: %s (%s)"):format(env.label, env.id), vim.log.levels.INFO)
    open_floating_terminal(enter_command(cmd, env))
  end)
end

---@type LazySpec
return {
  {
    name = "clouddev-local",
    dir = vim.fn.stdpath "config",
    lazy = false,
    config = function()
      vim.api.nvim_create_user_command("CloudDevStatus", function()
        render_status(status_summary())
      end, { desc = "Show Cloud Dev status" })

      vim.api.nvim_create_user_command("CloudDevList", function()
        local cmd = detect_command()
        if not cmd then
          vim.notify("Cloud Dev CLI not found", vim.log.levels.ERROR)
          return
        end

        open_floating_terminal(list_command(cmd))
      end, { desc = "List Cloud Dev environments" })

      vim.api.nvim_create_user_command("CloudDevSelect", function()
        get_envs(function(_, envs)
          prompt_for_env(envs, "Select Cloud Dev environment", function(choice)
            if not choice then return end
            set_selected_env(choice)
            vim.notify(("Selected Cloud Dev environment: %s (%s)"):format(choice.label, choice.id), vim.log.levels.INFO)
          end)
        end)
      end, { desc = "Select Cloud Dev environment" })

      vim.api.nvim_create_user_command("CloudDevEnter", function()
        if not state.selected_env then
          vim.notify("No Cloud Dev environment selected. Run :CloudDevSelect first.", vim.log.levels.WARN)
          return
        end

        local cmd = detect_command()
        if not cmd then
          vim.notify("Cloud Dev CLI not found", vim.log.levels.ERROR)
          return
        end

        vim.notify(("Entering Cloud Dev environment: %s (%s)"):format(state.selected_env.label, state.selected_env.id), vim.log.levels.INFO)
        open_floating_terminal(enter_command(cmd, state.selected_env))
      end, { desc = "Enter selected Cloud Dev environment" })

      vim.api.nvim_create_user_command("CloudDevAttach", function()
        local ctx = project_context()
        get_envs(function(cmd, envs)
          resolve_project_env(envs, ctx, function(env, source)
            set_selected_env(env)
            if ctx.root and source ~= "manual" then set_binding(ctx.root, env) end
            attach_env(cmd, env)
          end)
        end)
      end, { desc = "Attach Cloud Dev workspace" })

      vim.api.nvim_create_user_command("CloudDevBind", function()
        local ctx = project_context()
        if not ctx.root then
          vim.notify("CloudDevBind requires a git project root", vim.log.levels.WARN)
          return
        end

        get_envs(function(_, envs)
          prompt_for_env(envs, "Bind Cloud Dev workspace to project", function(choice)
            if not choice then return end
            set_binding(ctx.root, choice)
            set_selected_env(choice)
            vim.notify(("Bound Cloud Dev workspace: %s (%s)"):format(choice.label, choice.id), vim.log.levels.INFO)
          end)
        end)
      end, { desc = "Bind Cloud Dev workspace" })

      vim.api.nvim_create_user_command("CloudDevUnbind", function()
        local ctx = project_context()
        if not ctx.root then
          vim.notify("CloudDevUnbind requires a git project root", vim.log.levels.WARN)
          return
        end

        clear_binding(ctx.root)
        vim.notify("Cleared Cloud Dev workspace binding", vim.log.levels.INFO)
      end, { desc = "Unbind Cloud Dev workspace" })
    end,
  },
}
