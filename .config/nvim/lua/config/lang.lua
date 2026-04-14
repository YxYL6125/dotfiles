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
  return first_existing(vim.env.JAVA_HOME, vim.env.JDK21_HOME, vim.env.HOME and (vim.env.HOME .. "/workspace/env/jdk/jdk-21") or nil)
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

function M.smart_code_action(bufnr, opts)
  bufnr = bufnr or 0
  opts = opts or {}

  local params = vim.lsp.util.make_range_params()
  local cursor = vim.api.nvim_win_get_cursor(0)
  params.context = {
    diagnostics = opts.diagnostics == false and {} or vim.diagnostic.get(bufnr, { lnum = cursor[1] - 1 }),
    only = opts.only,
    triggerKind = 1,
  }

  vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(responses)
    local items = {}

    for client_id, response in pairs(responses or {}) do
      local client = vim.lsp.get_client_by_id(client_id)
      if client and response and response.result then
        for _, action in ipairs(response.result) do
          if not action.disabled then
            table.insert(items, { action = action, client = client })
          end
        end
      end
    end

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
  end)
end

function M.resolve_go_delve()
  return first_existing(vim.fn.stdpath "data" .. "/mason/bin/dlv", vim.fn.exepath "dlv", "dlv")
end

function M.resolve_rust_analyzer()
  return first_existing(vim.fn.stdpath "data" .. "/mason/bin/rust-analyzer", vim.fn.exepath "rust-analyzer", "rust-analyzer")
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
