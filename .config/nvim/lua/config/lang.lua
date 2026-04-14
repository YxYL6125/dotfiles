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
