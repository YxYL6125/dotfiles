local M = {}

local data = require "config.maven_data"
local known_plugin_goals = data.known_plugin_goals
local lifecycle_goals = data.lifecycle_goals

local history_limit = 30
local state_cache

local function exists(path) return path and path ~= "" and vim.uv.fs_stat(path) ~= nil end

local function read_text(path)
  local fd = io.open(path, "r")
  if not fd then return nil end
  local text = fd:read "*a"
  fd:close()
  return text
end

local function write_text(path, content)
  local dir = vim.fs.dirname(path)
  if dir and dir ~= "" then vim.fn.mkdir(dir, "p") end
  local fd = io.open(path, "w")
  if not fd then return false end
  fd:write(content)
  fd:close()
  return true
end

local function trim(text)
  text = tostring(text or "")
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Maven" })
end

local function single_quote(text)
  return "'" .. tostring(text):gsub("'", [['"'"']]) .. "'"
end

local function default_state() return { favorites = {}, history = {} } end

local function state_path() return vim.fn.stdpath("state") .. "/maven-tools.json" end

local function load_state()
  if state_cache then return state_cache end
  local text = read_text(state_path())
  if not text or text == "" then
    state_cache = default_state()
    return state_cache
  end
  local ok, decoded = pcall(vim.json.decode, text)
  if not ok or type(decoded) ~= "table" then
    state_cache = default_state()
    return state_cache
  end
  decoded.favorites = type(decoded.favorites) == "table" and decoded.favorites or {}
  decoded.history = type(decoded.history) == "table" and decoded.history or {}
  state_cache = decoded
  return state_cache
end

local function save_state()
  local ok, encoded = pcall(vim.json.encode, load_state())
  if not ok then
    notify("Maven 状态写入失败", vim.log.levels.ERROR)
    return false
  end
  if not write_text(state_path(), encoded) then
    notify("Maven 状态文件保存失败", vim.log.levels.ERROR)
    return false
  end
  return true
end

local function current_file_dir(startpath)
  local path = startpath or vim.api.nvim_buf_get_name(0)
  if path == nil or path == "" then return vim.fn.getcwd() end
  return vim.fs.dirname(vim.fs.normalize(path))
end

local function nearest_pom_dir(startpath)
  local source = current_file_dir(startpath)
  local pom = vim.fs.find("pom.xml", { path = source, upward = true })[1]
  return pom and vim.fs.dirname(pom) or nil
end

local function maven_root(startpath)
  local dir = nearest_pom_dir(startpath)
  if not dir then return nil end
  local highest = dir
  while true do
    local parent = vim.fs.dirname(highest)
    if not parent or parent == highest then break end
    if not exists(parent .. "/pom.xml") then break end
    highest = parent
  end
  return highest
end

local function normalize_module_rel(rel)
  rel = trim(rel)
  return (rel == "" or rel == ".") and "." or rel
end

local function module_name_from_pom(pom_path)
  local text = read_text(pom_path)
  if not text then return vim.fs.basename(vim.fs.dirname(pom_path)) end
  local project = text:match("<project.-</project>") or text
  project = project:gsub("<parent>.-</parent>", "")
  local artifact_id = project:match("<artifactId>%s*([^<]+)%s*</artifactId>")
  return trim(artifact_id or vim.fs.basename(vim.fs.dirname(pom_path)))
end

local function collect_module_entries(root)
  if not root then return nil end
  local pom_files = vim.fn.globpath(root, "**/pom.xml", false, true)
  local items = {}
  local seen = {}
  for _, pom_path in ipairs(pom_files) do
    pom_path = vim.fs.normalize(pom_path)
    if not pom_path:match("/target/") and not pom_path:match("/%.git/") and not pom_path:match("/node_modules/") then
      local dir = vim.fs.dirname(pom_path)
      if not seen[dir] then
        seen[dir] = true
        local rel = normalize_module_rel(vim.fs.relpath(root, dir) or ".")
        local name = module_name_from_pom(pom_path)
        table.insert(items, {
          dir = dir,
          pom = pom_path,
          rel = rel,
          name = name,
          label = rel == "." and (name .. "  [root]") or (name .. "  [" .. rel .. "]"),
        })
      end
    end
  end
  table.sort(items, function(a, b)
    if a.rel == b.rel then return a.name < b.name end
    if a.rel == "." then return true end
    if b.rel == "." then return false end
    return a.rel < b.rel
  end)
  return items
end

local function module_entries(startpath)
  local root = maven_root(startpath)
  if not root then return nil, nil end
  return root, collect_module_entries(root)
end

local function find_module_by_rel(root, rel)
  rel = normalize_module_rel(rel)
  for _, item in ipairs(collect_module_entries(root) or {}) do
    if normalize_module_rel(item.rel) == rel then return item end
  end
end

local function current_module(startpath)
  local root, items = module_entries(startpath)
  if not root or not items then return nil, nil end
  local module_dir = nearest_pom_dir(startpath) or root
  for _, item in ipairs(items) do
    if item.dir == module_dir then return root, item end
  end
  for _, item in ipairs(items) do
    if item.dir == root then return root, item end
  end
  return root, items[1]
end

local function pom_chain(module_dir, root)
  local chain = {}
  local dir = module_dir
  while dir and dir ~= "" do
    local pom = dir .. "/pom.xml"
    if exists(pom) then table.insert(chain, pom) end
    if dir == root then break end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then break end
    dir = parent
  end
  return chain
end

local function infer_plugin_prefix(artifact_id)
  local meta = known_plugin_goals[artifact_id]
  if meta and meta.prefix then return meta.prefix end
  return artifact_id:gsub("^maven%-", ""):gsub("%-maven%-plugin$", ""):gsub("%-plugin$", "")
end

local function collect_plugins(module_dir, root)
  local plugins = {}
  local seen = {}
  for _, pom in ipairs(pom_chain(module_dir, root)) do
    local text = read_text(pom)
    if text then
      for block in text:gmatch("<plugin>(.-)</plugin>") do
        local artifact_id = trim(block:match("<artifactId>%s*([^<]+)%s*</artifactId>") or "")
        if artifact_id ~= "" and not seen[artifact_id] then
          seen[artifact_id] = true
          local group_id = trim(block:match("<groupId>%s*([^<]+)%s*</groupId>") or "")
          local version = trim(block:match("<version>%s*([^<]+)%s*</version>") or "")
          local meta = known_plugin_goals[artifact_id]
          table.insert(plugins, {
            artifact_id = artifact_id,
            group_id = group_id,
            version = version,
            prefix = infer_plugin_prefix(artifact_id),
            goals = meta and vim.deepcopy(meta.goals) or {},
          })
        end
      end
    end
  end
  table.sort(plugins, function(a, b) return a.artifact_id < b.artifact_id end)
  return plugins
end

local function shell_double_quote(text)
  text = tostring(text or "")
  text = text:gsub("\\", "\\\\")
  text = text:gsub('"', '\\"')
  text = text:gsub("%$", "\\$")
  text = text:gsub("`", "\\`")
  return '"' .. text .. '"'
end

local function module_cli_args(module)
  local rel = normalize_module_rel(module and module.rel or ".")
  if rel == "." then return "" end
  return "-pl " .. shell_double_quote(rel) .. " -am"
end

local function mvn_command(root)
  if exists(root .. "/mvnw") then return "./mvnw" end
  return "mvn"
end

local function build_command(root, module, goal_or_args)
  local parts = { mvn_command(root) }
  local module_args = module_cli_args(module)
  if module_args ~= "" then table.insert(parts, module_args) end
  if goal_or_args and trim(goal_or_args) ~= "" then table.insert(parts, trim(goal_or_args)) end
  return table.concat(parts, " ")
end

local function add_history(entry)
  local state = load_state()
  local history = {}
  table.insert(history, entry)
  for _, item in ipairs(state.history or {}) do
    local same = item.root == entry.root and item.module_rel == entry.module_rel and item.command == entry.command
    if not same then table.insert(history, item) end
    if #history >= history_limit then break end
  end
  state.history = history
  save_state()
end

local function run_command(command, root, title, history_entry)
  if history_entry then add_history(history_entry) end
  local parts = { "TermExec", "direction=float", "go_back=0", "cmd=" .. single_quote(command) }
  if root and root ~= "" then table.insert(parts, "dir=" .. single_quote(root)) end
  if title and title ~= "" then table.insert(parts, "name=" .. single_quote(title)) end
  vim.cmd(table.concat(parts, " "))
end

local function run_goal_for_module(root, module, goal_or_args, title)
  local cmd = build_command(root, module, goal_or_args)
  local module_rel = normalize_module_rel(module and module.rel or ".")
  local module_name = module and module.name or vim.fs.basename(root)
  run_command(cmd, root, title or (module_name .. " mvn"), {
    root = root,
    module_rel = module_rel,
    module_name = module_name,
    command = trim(goal_or_args),
    title = title or trim(goal_or_args),
    timestamp = os.time(),
  })
end

local function get_snacks()
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.picker and snacks.picker.select then return snacks end
end

local function preview_payload(item) return item and (item.item or item) or nil end

local function set_preview_lines(buf, lines)
  lines = lines or { "No preview" }
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "markdown"
end

local function default_format_item(item)
  local section = item.section and ("[" .. item.section .. "] ") or ""
  return section .. (item.label or item.command or item.text or tostring(item))
end

local function picker_select(items, opts, on_choice)
  opts = opts or {}
  local format_item = opts.format_item or default_format_item
  local snacks = get_snacks()
  if snacks and opts.snacks ~= false then
    local actions = vim.tbl_extend("force", {}, opts.actions or {})
    local keymaps = opts.keys or {}
    return snacks.picker.select(items, {
      prompt = opts.prompt,
      format_item = format_item,
      snacks = {
        preview = opts.preview and function(ctx)
          local entry = preview_payload(ctx.item)
          set_preview_lines(ctx.buf, opts.preview(entry))
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
    format_item = format_item,
  }, on_choice)
end

local function copy_to_clipboard(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  notify("已复制命令: " .. text)
end

local function plugin_goal_command(plugin, goal)
  local group_id = trim(plugin and plugin.group_id or "")
  local artifact_id = trim(plugin and plugin.artifact_id or "")
  local version = trim(plugin and plugin.version or "")
  local prefix = trim(plugin and plugin.prefix or "")

  if group_id ~= "" and artifact_id ~= "" and version ~= "" then return table.concat({ group_id, artifact_id, version, goal }, ":") end
  if group_id ~= "" and artifact_id ~= "" then return table.concat({ group_id, artifact_id, goal }, ":") end
  if prefix ~= "" then return prefix .. ":" .. goal end
  return goal
end

local function lifecycle_items()
  local items = {}
  for _, goal in ipairs(lifecycle_goals) do
    table.insert(items, { command = goal, label = goal })
  end
  return items
end

local function plugin_goal_items(module_dir, root, filter_artifact)
  local items = {}
  for _, plugin in ipairs(collect_plugins(module_dir, root)) do
    if (not filter_artifact) or plugin.artifact_id == filter_artifact then
      for _, goal in ipairs(plugin.goals or {}) do
        table.insert(items, {
          kind = "plugin_goal",
          artifact_id = plugin.artifact_id,
          group_id = plugin.group_id,
          version = plugin.version,
          prefix = plugin.prefix,
          goal = goal,
          command = plugin_goal_command(plugin, goal),
          short_command = plugin.prefix .. ":" .. goal,
          label = plugin.prefix .. ":" .. goal,
        })
      end
    end
  end
  table.sort(items, function(a, b) return a.label < b.label end)
  return items
end

local function favorites_items()
  local items = {}
  for _, item in ipairs(load_state().favorites or {}) do
    table.insert(items, {
      command = trim(item.command),
      label = trim(item.label ~= "" and item.label or item.command),
    })
  end
  return items
end

local function project_history_items(root)
  local items = {}
  for _, item in ipairs(load_state().history or {}) do
    if (not root) or item.root == root then
      local module_rel = normalize_module_rel(item.module_rel ~= "" and item.module_rel or ".")
      local module_tag = module_rel == "." and "root" or module_rel
      local stamp = item.timestamp and os.date("%m-%d %H:%M", item.timestamp) or ""
      table.insert(items, {
        root = item.root,
        module_rel = module_rel,
        module_name = item.module_name,
        command = item.command,
        timestamp = item.timestamp,
        label = string.format("%s  [%s]%s", item.command, module_tag, stamp ~= "" and ("  " .. stamp) or ""),
      })
    end
  end
  return items
end

local function add_favorite(command, label)
  command = trim(command)
  if command == "" then
    notify("空命令不能收藏", vim.log.levels.WARN)
    return
  end
  local state = load_state()
  local favorites = {}
  table.insert(favorites, { command = command, label = trim(label ~= "" and label or command) })
  for _, item in ipairs(state.favorites or {}) do
    if trim(item.command) ~= command then table.insert(favorites, item) end
  end
  state.favorites = favorites
  save_state()
  notify("已收藏 Maven goal: " .. command)
end

local function remove_favorite(command)
  command = trim(command)
  local state = load_state()
  local favorites = {}
  local removed = false
  for _, item in ipairs(state.favorites or {}) do
    if trim(item.command) == command then
      removed = true
    else
      table.insert(favorites, item)
    end
  end
  state.favorites = favorites
  save_state()
  if removed then
    notify("已取消收藏: " .. command)
  else
    notify("没找到收藏: " .. command, vim.log.levels.WARN)
  end
end

local function prompt_add_favorite(default)
  vim.ui.input({ prompt = "收藏的 mvn args/goals: ", default = default or "test" }, function(input)
    if input and trim(input) ~= "" then add_favorite(input, input) end
  end)
end

local function command_preview_lines(root, module, item)
  local lines = {
    "# Maven Action",
    "",
    "- section: " .. (item.section or item.kind or "general"),
    "- label: " .. (item.label or item.command or ""),
    "- module: " .. (module and module.label or ""),
    "- root: " .. (root or ""),
  }
  if item.artifact_id and item.prefix then
    table.insert(lines, "- plugin: " .. item.prefix .. " (" .. item.artifact_id .. ")")
  end
  if item.short_command and item.short_command ~= item.command then
    table.insert(lines, "- alias: " .. item.short_command)
  end
  if item.module_rel then table.insert(lines, "- history module: " .. item.module_rel) end
  if item.command and item.command ~= "" then
    table.insert(lines, "")
    table.insert(lines, "## Command")
    table.insert(lines, "```")
    table.insert(lines, build_command(root, module, item.command))
    table.insert(lines, "```")
  end
  if item.note and item.note ~= "" then
    table.insert(lines, "")
    table.insert(lines, item.note)
  end
  return lines
end

local function module_preview_lines(item)
  return {
    "# Maven Module",
    "",
    "- module: " .. item.name,
    "- relative path: " .. item.rel,
    "- pom: " .. item.pom,
    "- dir: " .. item.dir,
  }
end

local function choose_module(startpath, prompt, on_choice)
  local root, items = module_entries(startpath)
  if not root or not items or vim.tbl_isempty(items) then
    notify("当前路径不在 Maven 项目里", vim.log.levels.WARN)
    return
  end
  picker_select(items, {
    prompt = prompt or "Maven modules",
    format_item = function(item) return item.label end,
    preview = module_preview_lines,
  }, function(choice)
    if choice then on_choice(root, choice) end
  end)
end

local function module_panel_items(root, module)
  local items = {}
  local function add(section, entry)
    entry.section = section
    entry.search = table.concat({ section, entry.label or "", entry.command or "", entry.artifact_id or "", entry.module_rel or "" }, " ")
    table.insert(items, entry)
  end

  add("Action", {
    kind = "custom_action",
    label = "Custom input…",
    note = "输入任意 Maven args/goals，回车后在当前模块执行。",
    run = function()
      vim.ui.input({ prompt = "mvn args/goals: ", default = "test" }, function(input)
        if input and trim(input) ~= "" then run_goal_for_module(root, module, input, "mvn custom") end
      end)
    end,
  })

  add("Action", {
    kind = "custom_action",
    label = "Add favorite…",
    note = "手工添加一个常用 Maven 命令到收藏。",
    run = function() prompt_add_favorite() end,
  })

  add("Action", {
    kind = "custom_action",
    label = "Remove favorite…",
    note = "从收藏列表里删一个命令。",
    run = function() M.favorite_remove() end,
  })

  for _, item in ipairs(favorites_items()) do
    add("Favorite", vim.tbl_extend("force", item, { kind = "favorite" }))
  end

  for _, item in ipairs(project_history_items(root)) do
    add("Recent", vim.tbl_extend("force", item, { kind = "history" }))
  end

  for _, item in ipairs(lifecycle_items()) do
    add("Lifecycle", vim.tbl_extend("force", item, { kind = "lifecycle" }))
  end

  for _, item in ipairs(plugin_goal_items(module.dir, root)) do
    local section = item.prefix == "thrift" and "Thrift" or "Plugin"
    add(section, item)
  end

  return items
end

local function run_panel_item(root, module, item)
  if item.run then
    item.run()
    return
  end
  if item.kind == "history" then
    local history_module = find_module_by_rel(root, item.module_rel) or module
    run_goal_for_module(root, history_module, item.command, item.command)
    return
  end
  if item.command and item.command ~= "" then
    run_goal_for_module(root, module, item.command, item.label or item.command)
  end
end

local function panel_actions(root, module)
  local function selected(item) return preview_payload(item) end
  return {
    add_favorite = function(_, item)
      local entry = selected(item)
      if not entry or not entry.command then
        notify("当前项不是可收藏命令", vim.log.levels.WARN)
        return
      end
      add_favorite(entry.command, entry.label or entry.command)
    end,
    remove_favorite = function(_, item)
      local entry = selected(item)
      if not entry or not entry.command then
        notify("当前项没有可移除的命令", vim.log.levels.WARN)
        return
      end
      remove_favorite(entry.command)
    end,
    copy_command = function(_, item)
      local entry = selected(item)
      if not entry or not entry.command then
        notify("当前项没有可复制的命令", vim.log.levels.WARN)
        return
      end
      local target_module = entry.kind == "history" and (find_module_by_rel(root, entry.module_rel) or module) or module
      copy_to_clipboard(build_command(root, target_module, entry.command))
    end,
  }
end

local function module_panel(root, module)
  local items = module_panel_items(root, module)
  picker_select(items, {
    prompt = "Maven panel › " .. module.label,
    format_item = function(item)
      local icon = ({ Action = "⚙", Favorite = "★", Recent = "", Lifecycle = "λ", Plugin = "󰏗", Thrift = "󰘦" })[item.section] or "•"
      local extra = item.artifact_id and ("  (" .. item.artifact_id .. ")") or ""
      local history_tag = item.module_rel and ("  [" .. item.module_rel .. "]") or ""
      return string.format("%s %-10s %s%s%s", icon, item.section, item.label or item.command or "", extra, history_tag)
    end,
    preview = function(item) return command_preview_lines(root, module, item) end,
    keys = {
      ["<C-a>"] = { "add_favorite", mode = { "n", "i" } },
      ["<C-d>"] = { "remove_favorite", mode = { "n", "i" } },
      ["<C-y>"] = { "copy_command", mode = { "n", "i" } },
    },
    actions = panel_actions(root, module),
  }, function(choice)
    if choice then run_panel_item(root, module, choice) end
  end)
end

function M.menu(startpath)
  local root, module = current_module(startpath)
  if not root or not module then
    notify("当前 buffer 没找到 Maven module", vim.log.levels.WARN)
    return
  end
  local scopes = {
    {
      label = "当前模块 › " .. module.label,
      note = "打开当前模块的 Snacks Maven 分组大面板。",
      run = function() module_panel(root, module) end,
    },
    {
      label = "选择模块 › 打开大面板",
      note = "先选模块，再打开对应模块的大面板。",
      run = function()
        picker_select(collect_module_entries(root), {
          prompt = "Maven modules",
          format_item = function(item) return item.label end,
          preview = module_preview_lines,
        }, function(choice)
          if choice then module_panel(root, choice) end
        end)
      end,
    },
  }
  picker_select(scopes, {
    prompt = "Maven actions",
    format_item = function(item) return item.label end,
    preview = function(item) return { "# Maven Menu", "", item.note or item.label } end,
  }, function(choice)
    if choice then choice.run() end
  end)
end

function M.run_lifecycle(startpath)
  local root, module = current_module(startpath)
  if not root or not module then
    notify("当前 buffer 没找到 Maven module", vim.log.levels.WARN)
    return
  end
  picker_select(lifecycle_items(), {
    prompt = "Maven lifecycle",
    format_item = function(item) return item.label end,
    preview = function(item) return command_preview_lines(root, module, { section = "Lifecycle", label = item.label, command = item.command }) end,
  }, function(choice)
    if choice then run_goal_for_module(root, module, choice.command, choice.command) end
  end)
end

function M.run_lifecycle_select_module(startpath)
  choose_module(startpath, "选择模块后执行 lifecycle", function(root, module)
    picker_select(lifecycle_items(), {
      prompt = "Maven lifecycle",
      format_item = function(item) return item.label end,
      preview = function(item) return command_preview_lines(root, module, { section = "Lifecycle", label = item.label, command = item.command }) end,
    }, function(choice)
      if choice then run_goal_for_module(root, module, choice.command, choice.command) end
    end)
  end)
end

function M.run_plugin_goal(startpath)
  local root, module = current_module(startpath)
  if not root or not module then
    notify("当前 buffer 没找到 Maven module", vim.log.levels.WARN)
    return
  end
  local items = plugin_goal_items(module.dir, root)
  if vim.tbl_isempty(items) then
    notify("当前模块没识别到常见 Maven 插件 goal", vim.log.levels.WARN)
    return
  end
  picker_select(items, {
    prompt = "Maven plugin goals",
    format_item = function(item) return string.format("%s  (%s)", item.label, item.artifact_id) end,
    preview = function(item) return command_preview_lines(root, module, vim.tbl_extend("force", item, { section = "Plugin" })) end,
  }, function(choice)
    if choice then run_goal_for_module(root, module, choice.command, choice.command) end
  end)
end

function M.run_plugin_goal_select_module(startpath)
  choose_module(startpath, "选择模块后执行 plugin goal", function(root, module)
    local items = plugin_goal_items(module.dir, root)
    if vim.tbl_isempty(items) then
      notify("选中模块没识别到常见 Maven 插件 goal", vim.log.levels.WARN)
      return
    end
    picker_select(items, {
      prompt = "Maven plugin goals",
      format_item = function(item) return string.format("%s  (%s)", item.label, item.artifact_id) end,
      preview = function(item) return command_preview_lines(root, module, vim.tbl_extend("force", item, { section = "Plugin" })) end,
    }, function(choice)
      if choice then run_goal_for_module(root, module, choice.command, choice.command) end
    end)
  end)
end

function M.run_thrift_goal(startpath)
  local root, module = current_module(startpath)
  if not root or not module then
    notify("当前 buffer 没找到 Maven module", vim.log.levels.WARN)
    return
  end
  local items = plugin_goal_items(module.dir, root, "maven-thrift-plugin")
  if vim.tbl_isempty(items) then
    notify("当前模块没识别到 maven-thrift-plugin", vim.log.levels.WARN)
    return
  end
  picker_select(items, {
    prompt = "Maven thrift goals",
    format_item = function(item) return item.label end,
    preview = function(item) return command_preview_lines(root, module, vim.tbl_extend("force", item, { section = "Thrift" })) end,
  }, function(choice)
    if choice then run_goal_for_module(root, module, choice.command, choice.command) end
  end)
end

function M.run_custom(startpath, args)
  local root, module = current_module(startpath)
  if not root or not module then
    notify("当前 buffer 没找到 Maven module", vim.log.levels.WARN)
    return
  end
  vim.ui.input({ prompt = "mvn args/goals: ", default = args or "test" }, function(input)
    if input and trim(input) ~= "" then run_goal_for_module(root, module, input, "mvn custom") end
  end)
end

function M.run_custom_select_module(startpath, args)
  choose_module(startpath, "选择模块后执行自定义 mvn", function(root, module)
    vim.ui.input({ prompt = "mvn args/goals: ", default = args or "test" }, function(input)
      if input and trim(input) ~= "" then run_goal_for_module(root, module, input, "mvn custom") end
    end)
  end)
end

function M.run_favorites(startpath)
  local root, module = current_module(startpath)
  if not root or not module then
    notify("当前 buffer 没找到 Maven module", vim.log.levels.WARN)
    return
  end
  local items = favorites_items()
  if vim.tbl_isempty(items) then
    notify("还没有收藏的 Maven goals", vim.log.levels.WARN)
    return
  end
  picker_select(items, {
    prompt = "Maven favorites",
    format_item = function(item) return item.label end,
    preview = function(item) return command_preview_lines(root, module, vim.tbl_extend("force", item, { section = "Favorite" })) end,
  }, function(choice)
    if choice then run_goal_for_module(root, module, choice.command, choice.label) end
  end)
end

function M.run_favorites_select_module(startpath)
  choose_module(startpath, "选择模块后执行收藏 goal", function(root, module)
    local items = favorites_items()
    if vim.tbl_isempty(items) then
      notify("还没有收藏的 Maven goals", vim.log.levels.WARN)
      return
    end
    picker_select(items, {
      prompt = "Maven favorites",
      format_item = function(item) return item.label end,
      preview = function(item) return command_preview_lines(root, module, vim.tbl_extend("force", item, { section = "Favorite" })) end,
    }, function(choice)
      if choice then run_goal_for_module(root, module, choice.command, choice.label) end
    end)
  end)
end

function M.show_history(startpath)
  local root = maven_root(startpath)
  if not root then
    notify("当前路径不在 Maven 项目里", vim.log.levels.WARN)
    return
  end
  local module = find_module_by_rel(root, nearest_pom_dir(startpath) and (vim.fs.relpath(root, nearest_pom_dir(startpath)) or ".") or ".") or find_module_by_rel(root, ".")
  local items = project_history_items(root)
  if vim.tbl_isempty(items) then
    notify("当前项目还没有 Maven 历史", vim.log.levels.WARN)
    return
  end
  picker_select(items, {
    prompt = "Maven history",
    format_item = function(item) return item.label end,
    preview = function(item)
      local target_module = find_module_by_rel(root, item.module_rel) or module
      return command_preview_lines(root, target_module, vim.tbl_extend("force", item, { section = "Recent" }))
    end,
  }, function(choice)
    if choice then
      local target_module = find_module_by_rel(root, choice.module_rel) or module
      run_goal_for_module(root, target_module, choice.command, choice.command)
    end
  end)
end

function M.favorite_add(goal)
  if goal and trim(goal) ~= "" then
    add_favorite(goal, goal)
    return
  end
  prompt_add_favorite()
end

function M.favorite_add_prompt(default_goal) prompt_add_favorite(default_goal) end

function M.favorite_add_from_history(startpath)
  local root = maven_root(startpath)
  if not root then
    notify("当前路径不在 Maven 项目里", vim.log.levels.WARN)
    return
  end
  local items = project_history_items(root)
  if vim.tbl_isempty(items) then
    notify("当前项目还没有 Maven 历史", vim.log.levels.WARN)
    return
  end
  picker_select(items, {
    prompt = "从历史里选一个加入收藏",
    format_item = function(item) return item.label end,
    preview = function(item)
      local module = find_module_by_rel(root, item.module_rel) or find_module_by_rel(root, ".")
      return command_preview_lines(root, module, vim.tbl_extend("force", item, { section = "Recent" }))
    end,
  }, function(choice)
    if choice then add_favorite(choice.command, choice.command) end
  end)
end

function M.favorite_remove(goal)
  if goal and trim(goal) ~= "" then
    remove_favorite(goal)
    return
  end
  local items = favorites_items()
  if vim.tbl_isempty(items) then
    notify("没有收藏项可删除", vim.log.levels.WARN)
    return
  end
  picker_select(items, {
    prompt = "移除收藏的 Maven goal",
    format_item = function(item) return item.label end,
    preview = function(item) return { "# Remove favorite", "", "- command: " .. item.command } end,
  }, function(choice)
    if choice then remove_favorite(choice.command) end
  end)
end

local command_specs = {
  { "MavenMenu", function() M.menu() end, { desc = "Maven grouped panel" } },
  { "MavenLifecycle", function() M.run_lifecycle() end, { desc = "Run Maven lifecycle goal for current module" } },
  { "MavenLifecycleSelectModule", function() M.run_lifecycle_select_module() end, { desc = "Run Maven lifecycle goal for selected module" } },
  { "MavenPluginGoal", function() M.run_plugin_goal() end, { desc = "Run Maven plugin goal for current module" } },
  { "MavenPluginGoalSelectModule", function() M.run_plugin_goal_select_module() end, { desc = "Run Maven plugin goal for selected module" } },
  { "MavenThrift", function() M.run_thrift_goal() end, { desc = "Run Maven thrift goal for current module" } },
  { "MavenFavorites", function() M.run_favorites() end, { desc = "Run favorite Maven goal for current module" } },
  { "MavenFavoritesSelectModule", function() M.run_favorites_select_module() end, { desc = "Run favorite Maven goal for selected module" } },
  { "MavenHistory", function() M.show_history() end, { desc = "Show recent Maven command history for current project" } },
  {
    "MavenFavoriteAdd",
    function(opts) M.favorite_add(opts.args ~= "" and opts.args or nil) end,
    { desc = "Add favorite Maven goal", nargs = "*" },
  },
  { "MavenFavoriteAddFromHistory", function() M.favorite_add_from_history() end, { desc = "Add favorite Maven goal from project history" } },
  {
    "MavenFavoriteRemove",
    function(opts) M.favorite_remove(opts.args ~= "" and opts.args or nil) end,
    { desc = "Remove favorite Maven goal", nargs = "*" },
  },
  {
    "MavenRun",
    function(opts) M.run_custom(nil, opts.args ~= "" and opts.args or nil) end,
    { desc = "Run custom Maven command for current module", nargs = "*" },
  },
  {
    "MavenRunSelectModule",
    function(opts) M.run_custom_select_module(nil, opts.args ~= "" and opts.args or nil) end,
    { desc = "Run custom Maven command for selected module", nargs = "*" },
  },
  {
    "MavenReload",
    function()
      package.loaded["config.maven"] = nil
      require("config.maven").setup()
      vim.notify("Maven config reloaded", vim.log.levels.INFO, { title = "Maven" })
    end,
    { desc = "Reload Maven config" },
  },
}

function M.setup()
  local function command(name, rhs, opts)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, rhs, opts)
  end

  vim.g.maven_tools_loaded = true
  for _, spec in ipairs(command_specs) do
    command(spec[1], spec[2], spec[3])
  end
end

M._debug = {
  collect_module_entries = collect_module_entries,
  current_module = current_module,
  collect_plugins = collect_plugins,
  plugin_goal_items = plugin_goal_items,
  favorites_items = favorites_items,
  project_history_items = project_history_items,
  state_path = state_path,
  load_state = load_state,
  module_panel_items = module_panel_items,
  build_command = build_command,
}

return M
