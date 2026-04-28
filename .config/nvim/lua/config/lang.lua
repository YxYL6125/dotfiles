local M = {}

local function first_existing(...)
  for i = 1, select("#", ...) do
    local path = select(i, ...)
    if path and path ~= "" and vim.uv.fs_stat(path) then return path end
  end
end

local function first_gopath_bin(binary)
  if not vim.env.GOPATH or vim.env.GOPATH == "" then return end

  for _, entry in ipairs(vim.split(vim.env.GOPATH, ":", { trimempty = true })) do
    local path = entry .. "/bin/" .. binary
    if vim.uv.fs_stat(path) then return path end
  end
end

function M.first_existing(...) return first_existing(...) end

function M.resolve_java_home()
  return first_existing(
    vim.env.JAVA_HOME,
    vim.env.JDK21_HOME,
    vim.env.HOME and (vim.env.HOME .. "/workspace/env/jdk/jdk-21") or nil
  )
end

function M.resolve_java_executable()
  local java_home = M.resolve_java_home()
  return first_existing(
    java_home and (java_home .. "/bin/java") or nil,
    vim.env.JDK21_HOME and (vim.env.JDK21_HOME .. "/bin/java") or nil,
    vim.fn.exepath "java",
    "java"
  )
end

function M.resolve_lombok_jar() return first_existing(vim.fn.stdpath "data" .. "/mason/packages/jdtls/lombok.jar") end

function M.java_root_dir(startpath)
  local path = startpath or vim.api.nvim_buf_get_name(0)
  if not path or path == "" then return end

  local source = vim.fs.dirname(vim.fs.normalize(path))
  local root_markers = { ".git", "mvnw", "gradlew", "build.gradle", "build.gradle.kts" }
  local root_hits = vim.fs.find(root_markers, { path = source, upward = true })
  local root_dir = root_hits[1] and vim.fs.dirname(root_hits[1]) or nil

  local pom_path = vim.fs.find("pom.xml", { path = source, upward = true })[1]
  local pom_dir = pom_path and vim.fs.dirname(pom_path) or nil
  if not pom_dir then return root_dir end

  local highest_pom_dir = pom_dir
  while true do
    local parent_dir = vim.fs.dirname(highest_pom_dir)
    if not parent_dir or parent_dir == highest_pom_dir then break end
    if root_dir and not vim.startswith(parent_dir, root_dir) then break end
    if not vim.uv.fs_stat(parent_dir .. "/pom.xml") then break end
    highest_pom_dir = parent_dir
  end

  if root_dir and vim.startswith(highest_pom_dir, root_dir) then return highest_pom_dir end
  return pom_dir
end

function M.resolve_debugpy_python()
  return first_existing(
    vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python",
    vim.fn.exepath "python3",
    vim.fn.exepath "python",
    "python3"
  )
end

local function code_action_label(action)
  local title = action.title or "Untitled"
  if action.kind and action.kind ~= "" then return title .. " [" .. action.kind .. "]" end
  return title
end

local function apply_code_action(action, client)
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client and client.offset_encoding or "utf-16")
  end

  if action.command then vim.lsp.buf.execute_command(action.command) end
end

local function buffer_position_encoding(bufnr, fallback)
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client and client.offset_encoding then return client.offset_encoding end
  end
  return fallback or "utf-16"
end

function M.buffer_position_encoding(bufnr, fallback)
  return buffer_position_encoding(bufnr or 0, fallback)
end

function M.smart_code_action(bufnr, opts)
  bufnr = bufnr or 0
  opts = opts or {}

  local position_encoding = opts.position_encoding or M.buffer_position_encoding(bufnr, "utf-16")
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1] - 1
  local diagnostics = {}

  if opts.diagnostics ~= false then
    diagnostics = vim.diagnostic.get(bufnr, { lnum = current_line })
    if vim.tbl_isempty(diagnostics) then diagnostics = vim.diagnostic.get(bufnr) end
  end

  local function range_from_cursor()
    local col = cursor[2]
    return {
      start = { line = current_line, character = col },
      ["end"] = { line = current_line, character = col },
    }
  end

  local function range_from_diagnostic(diagnostic)
    if not diagnostic then return nil end

    local lsp_diagnostic = diagnostic.user_data and diagnostic.user_data.lsp
    if lsp_diagnostic and lsp_diagnostic.range then return lsp_diagnostic.range end

    if diagnostic.lnum and diagnostic.col then
      return {
        start = { line = diagnostic.lnum, character = diagnostic.col },
        ["end"] = {
          line = diagnostic.end_lnum or diagnostic.lnum,
          character = diagnostic.end_col or diagnostic.col,
        },
      }
    end
  end

  local candidate_ranges = {}
  local seen_ranges = {}
  local function add_candidate_range(range)
    if not range then return end
    local key = vim.inspect(range)
    if seen_ranges[key] then return end
    seen_ranges[key] = true
    table.insert(candidate_ranges, range)
  end

  add_candidate_range(range_from_cursor())
  for _, diagnostic in ipairs(diagnostics) do
    add_candidate_range(range_from_diagnostic(diagnostic))
  end

  local seen = {}
  local function collect_items(responses, items)
    for client_id, response in pairs(responses or {}) do
      local client = vim.lsp.get_client_by_id(client_id)
      if client and response and response.result then
        for _, action in ipairs(response.result) do
          if not action.disabled then
            local key = code_action_label(action) .. "|" .. tostring(action.kind or "")
            if not seen[key] then
              seen[key] = true
              table.insert(items, { action = action, client = client })
            end
          end
        end
      end
    end
  end

  local function lsp_diagnostics(items)
    local converted = {}
    for _, diagnostic in ipairs(items or {}) do
      table.insert(converted, diagnostic.user_data and diagnostic.user_data.lsp or diagnostic)
    end
    return converted
  end

  local function request_for_range(range, on_done)
    local params = vim.lsp.util.make_range_params(0, position_encoding)
    params.range = range
    params.context = {
      diagnostics = lsp_diagnostics(diagnostics),
      only = opts.only,
      triggerKind = 1,
    }
    vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, on_done)
  end

  local function run_candidate(index, items)
    if index > #candidate_ranges then
      if vim.tbl_isempty(items) then
        if opts.notify ~= false then
          vim.schedule(function() vim.notify("No code actions available", vim.log.levels.INFO) end)
        end
        return
      end

      table.sort(items, function(a, b)
        if a.action.isPreferred ~= b.action.isPreferred then return a.action.isPreferred end
        return code_action_label(a.action) < code_action_label(b.action)
      end)

      local function prompt_select()
        vim.schedule(function()
          vim.ui.select(items, {
            prompt = opts.prompt or "Code actions",
            format_item = function(item) return code_action_label(item.action) end,
          }, function(choice)
            if choice then apply_code_action(choice.action, choice.client) end
          end)
        end)
      end

      if opts.apply == true and #items == 1 then
        vim.schedule(function() apply_code_action(items[1].action, items[1].client) end)
        return
      end

      prompt_select()
      return
    end

    request_for_range(candidate_ranges[index], function(responses)
      local next_items = vim.deepcopy(items)
      collect_items(responses, next_items)
      if vim.tbl_isempty(next_items) then
        run_candidate(index + 1, items)
        return
      end
      run_candidate(#candidate_ranges + 1, next_items)
    end)
  end

  run_candidate(1, {})
end

local lsp_location_methods = {
  declaration = "textDocument/declaration",
  definition = "textDocument/definition",
  implementation = "textDocument/implementation",
  references = "textDocument/references",
  type_definition = "textDocument/typeDefinition",
}

local lsp_picker_names = {
  declaration = "lsp_declarations",
  definition = "lsp_definitions",
  implementation = "lsp_implementations",
  references = "lsp_references",
  type_definition = "lsp_type_definitions",
  incoming_calls = "lsp_incoming_calls",
  outgoing_calls = "lsp_outgoing_calls",
}

local function supports_method(client, method, bufnr)
  local ok, supported = pcall(client.supports_method, client, method, bufnr)
  if ok then return supported end

  ok, supported = pcall(client.supports_method, client, method)
  return ok and supported or false
end

function M.supports_lsp_method(bufnr, method)
  bufnr = bufnr or 0
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if supports_method(client, method, bufnr) then return true end
  end
  return false
end

function M.supports_lsp_location(bufnr)
  bufnr = bufnr or 0
  for _, method in pairs(lsp_location_methods) do
    if method ~= "textDocument/references" and M.supports_lsp_method(bufnr, method) then return true end
  end
  return false
end

local function normalize_lsp_locations(result)
  if not result or vim.tbl_isempty(result) then return {} end
  if result.uri or result.targetUri then return { result } end

  local islist = vim.islist or vim.tbl_islist
  if islist and islist(result) then return result end
  return { result }
end

local function location_range(location)
  return location.targetSelectionRange or location.targetRange or location.range
end

local function is_current_location(bufnr, location)
  local range = location_range(location)
  if not range then return false end

  local uri = location.targetUri or location.uri
  local current_uri = vim.uri_from_fname(vim.api.nvim_buf_get_name(bufnr))
  if uri ~= current_uri then return false end

  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local start_line = range.start and range.start.line or line
  local end_line = range["end"] and range["end"].line or start_line
  return start_line <= line and line <= end_line
end

local function request_lsp_locations(bufnr, kind, opts)
  bufnr = bufnr or 0
  opts = opts or {}

  local method = lsp_location_methods[kind] or kind
  if not M.supports_lsp_method(bufnr, method) then return {} end

  local params = vim.lsp.util.make_position_params(0, M.buffer_position_encoding(bufnr, "utf-16"))
  if method == "textDocument/references" then
    params.context = { includeDeclaration = opts.include_declaration == true }
  end

  local responses = vim.lsp.buf_request_sync(bufnr, method, params, opts.timeout_ms or 1200) or {}
  local locations = {}

  for _, response in pairs(responses) do
    if response and not response.err then
      for _, location in ipairs(normalize_lsp_locations(response.result)) do
        if opts.include_current ~= false or not is_current_location(bufnr, location) then
          locations[#locations + 1] = location
        end
      end
    end
  end

  return locations
end

local function notify_no_location(label)
  vim.notify("No LSP " .. label .. " found", vim.log.levels.INFO)
end

local function lsp_position_encoding_from_ctx(ctx, bufnr)
  if ctx and ctx.client_id then
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client and client.offset_encoding then return client.offset_encoding end
  end
  return M.buffer_position_encoding(bufnr or 0, "utf-16")
end

function M.java_show_references(command, ctx)
  local arguments = command and command.arguments or command or {}
  local locations = arguments[3] or {}
  local bufnr = ctx and ctx.bufnr or 0
  local encoding = lsp_position_encoding_from_ctx(ctx, bufnr)

  if vim.tbl_isempty(locations) then
    notify_no_location("Java references")
    return
  end

  if #locations == 1 then
    vim.lsp.util.show_document(locations[1], encoding, { reuse_win = true, focus = true })
    return
  end

  local items = vim.lsp.util.locations_to_items(locations, encoding)
  vim.fn.setqflist({}, " ", { title = "Java references", items = items })

  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker and snacks.picker.qflist then
    snacks.picker.qflist { title = "Java references" }
    return
  end

  vim.cmd "silent! botright copen"
end

local function current_word()
  return vim.fn.expand "<cword>"
end

local function lsp_workspace_root(bufnr)
  bufnr = bufnr or 0
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    local root = client.config and client.config.root_dir
    if root and root ~= "" then return root end
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  return (name ~= "" and vim.fs.dirname(name)) or vim.fn.getcwd()
end

local function grep_word(bufnr, opts)
  opts = opts or {}
  local word = opts.word or current_word()
  if word == "" then return end

  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker or not snacks.picker.grep then
    notify_no_location("references")
    return
  end

  snacks.picker.grep(vim.tbl_deep_extend("force", {
    cwd = opts.cwd or lsp_workspace_root(bufnr),
    search = word,
    regex = false,
    args = { "--word-regexp" },
  }, opts.grep or {}))
end

local function open_lsp_picker(kind, opts)
  opts = opts or {}
  local picker_name = lsp_picker_names[kind]
  local ok, snacks = pcall(require, "snacks")

  if ok and picker_name and snacks.picker and snacks.picker[picker_name] then
    snacks.picker[picker_name](vim.tbl_deep_extend("force", {
      auto_confirm = true,
      include_current = false,
      jump = { tagstack = true, reuse_win = true },
    }, opts))
    return true
  end

  if kind == "declaration" then
    vim.lsp.buf.declaration()
  elseif kind == "definition" then
    vim.lsp.buf.definition()
  elseif kind == "implementation" then
    vim.lsp.buf.implementation()
  elseif kind == "references" then
    local ok_refs = pcall(
      vim.lsp.buf.references,
      { includeDeclaration = opts.include_declaration == true }
    )
    if not ok_refs then vim.lsp.buf.references() end
  elseif kind == "type_definition" then
    vim.lsp.buf.type_definition()
  else
    return false
  end

  return true
end

function M.thrift_workspace_root(bufnr)
  bufnr = bufnr or 0
  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if client.name == "thriftls" and client.config and client.config.root_dir then
      return client.config.root_dir
    end
  end

  local fname = vim.api.nvim_buf_get_name(bufnr)
  local source = fname ~= "" and vim.fs.dirname(fname) or vim.fn.getcwd()
  local marker = vim.fs.find({ ".git", "buf.yaml", "buf.work.yaml" }, { path = source, upward = true })[1]
  return marker and vim.fs.dirname(marker) or source
end

function M.thrift_search_references(bufnr)
  grep_word(bufnr or 0, {
    cwd = M.thrift_workspace_root(bufnr or 0),
    grep = { glob = "*.thrift" },
  })
end

function M.thrift_search_definition(bufnr)
  bufnr = bufnr or 0
  local word = current_word()
  if word == "" then return end

  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker or not snacks.picker.grep then
    notify_no_location("definition")
    return
  end

  local escaped = word:gsub("([^%w_])", "\\%1")
  local declaration_prefix = "(struct|union|exception|service|enum)\\s+"
  local alias_prefix = "(typedef|const)\\s+.*\\s+"
  local pattern = "^\\s*((" .. declaration_prefix .. escaped .. "\\b)|(" .. alias_prefix .. escaped .. "\\b))"

  snacks.picker.grep {
    cwd = M.thrift_workspace_root(bufnr),
    search = pattern,
    regex = true,
    glob = "*.thrift",
  }
end

function M.thrift_definition_or_search(bufnr)
  bufnr = bufnr or 0
  if #request_lsp_locations(bufnr, "definition", { include_current = false, timeout_ms = 800 }) > 0 then
    open_lsp_picker("definition")
    return
  end

  M.thrift_search_definition(bufnr)
end

function M.thrift_references_or_search(bufnr, opts)
  bufnr = bufnr or 0
  opts = opts or {}
  if #request_lsp_locations(bufnr, "references", {
    include_current = false,
    include_declaration = opts.include_declaration == true,
    timeout_ms = 800,
  }) > 0 then
    open_lsp_picker("references", {
      include_current = false,
      include_declaration = opts.include_declaration == true,
    })
    return
  end

  M.thrift_search_references(bufnr)
end

function M.lsp_location(kind, bufnr, opts)
  bufnr = bufnr or 0
  opts = opts or {}

  if vim.bo[bufnr].filetype == "thrift" and kind == "definition" then
    M.thrift_definition_or_search(bufnr)
    return
  end

  if vim.bo[bufnr].filetype == "thrift" and kind == "references" then
    M.thrift_references_or_search(bufnr, opts)
    return
  end

  local method = lsp_location_methods[kind]
  if not method or not M.supports_lsp_method(bufnr, method) then
    if kind == "references" then
      grep_word(bufnr)
    else
      notify_no_location(kind:gsub("_", " "))
    end
    return
  end

  if kind == "references" then
    opts = vim.tbl_deep_extend("force", { include_current = false, include_declaration = false }, opts)
  end

  open_lsp_picker(kind, opts)
end

function M.smart_lsp_jump(bufnr)
  bufnr = bufnr or 0

  local sequence = { "implementation", "definition", "type_definition", "declaration" }
  if vim.bo[bufnr].filetype == "thrift" then
    sequence = { "definition", "implementation", "type_definition", "declaration" }
  end

  for _, kind in ipairs(sequence) do
    if #request_lsp_locations(bufnr, kind, { include_current = false, timeout_ms = 1200 }) > 0 then
      open_lsp_picker(kind, { include_current = false })
      return
    end
  end

  if vim.bo[bufnr].filetype == "thrift" then
    M.thrift_search_definition(bufnr)
    return
  end

  notify_no_location("definition/implementation")
end

function M.lsp_call_hierarchy(kind, bufnr)
  bufnr = bufnr or 0
  if not M.supports_lsp_method(bufnr, "textDocument/prepareCallHierarchy") then
    notify_no_location(kind:gsub("_", " "))
    return
  end

  open_lsp_picker(kind, { include_current = false })
end

function M.resolve_go_delve()
  return first_existing(vim.fn.stdpath "data" .. "/mason/bin/dlv", vim.fn.exepath "dlv", "dlv")
end

function M.resolve_rust_analyzer()
  return first_existing(
    vim.fn.stdpath "data" .. "/mason/bin/rust-analyzer",
    vim.fn.exepath "rust-analyzer",
    "rust-analyzer"
  )
end

function M.resolve_thriftls()
  local data = vim.fn.stdpath "data"
  return first_existing(
    data .. "/mason/bin/thriftls",
    vim.fn.exepath "thriftls",
    first_gopath_bin "thriftls",
    (vim.env.HOME and (vim.env.HOME .. "/go/bin/thriftls") or nil)
  )
end

function M.resolve_codelldb()
  return first_existing(vim.fn.stdpath "data" .. "/mason/bin/codelldb", vim.fn.exepath "codelldb", "codelldb")
end

function M.resolve_rust_debug_executable()
  local cwd = vim.fn.getcwd()
  local project = vim.fs.basename(cwd)
  local candidate = cwd .. "/target/debug/" .. project
  if vim.uv.fs_stat(candidate) then return candidate end
  return vim.fn.input("Path to executable: ", candidate, "file")
end

function M.resolve_jdtls_bundles()
  local data = vim.fn.stdpath "data"
  local bundles = {}

  local function add_glob(glob)
    vim.list_extend(bundles, vim.split(vim.fn.glob(glob), "\n", { trimempty = true }))
  end

  add_glob(data .. "/mason/packages/java-debug-adapter/extension/server/*.jar")
  add_glob(data .. "/mason/packages/java-test/extension/server/*junit*.jar")
  add_glob(data .. "/mason/packages/java-test/extension/server/com.microsoft.java.test.plugin-*.jar")
  add_glob(data .. "/mason/packages/java-test/extension/server/org.apiguardian.api_*.jar")
  add_glob(data .. "/mason/packages/java-test/extension/server/org.opentest4j_*.jar")
  add_glob(data .. "/mason/packages/java-test/extension/server/org.jacoco.core_*.jar")

  return bundles
end

function M.java_workspace_dir(root_dir)
  local source = root_dir and vim.fs.normalize(root_dir) or vim.fs.normalize(vim.fn.getcwd())
  local project = vim.fs.basename(source)
  local hash = vim.fn.sha256(source):sub(1, 12)
  return vim.fn.stdpath "data" .. "/site/java/workspace-root/" .. project .. "-" .. hash
end

return M
