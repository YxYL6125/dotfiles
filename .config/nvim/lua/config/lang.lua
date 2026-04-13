local M = {}

local function first_existing(...)
  for i = 1, select("#", ...) do
    local path = select(i, ...)
    if path and path ~= "" and vim.uv.fs_stat(path) then return path end
  end
end

function M.first_existing(...) return first_existing(...) end

function M.resolve_java_home()
  return first_existing(vim.env.JAVA_HOME, vim.env.JDK21_HOME, "/Users/bytedance/workspace/env/jdk/jdk-21")
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

  vim.list_extend(
    bundles,
    vim.split(
      vim.fn.glob(data .. "/mason/packages/java-debug-adapter/extension/server/*.jar"),
      "\n",
      { trimempty = true }
    )
  )
  vim.list_extend(
    bundles,
    vim.split(vim.fn.glob(data .. "/mason/packages/java-test/extension/server/*.jar"), "\n", { trimempty = true })
  )

  return bundles
end

function M.java_workspace_dir()
  local project = vim.fs.basename(vim.fn.getcwd())
  return vim.fn.stdpath "data" .. "/site/java/workspace-root/" .. project
end

return M
