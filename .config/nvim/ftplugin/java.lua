local ok, jdtls = pcall(require, "jdtls")
if not ok then return end

local lang = require "config.lang"

vim.lsp.commands["java.show.references"] = function(command, ctx)
  lang.java_show_references(command, ctx)
end

local root_dir = lang.java_root_dir()
if not root_dir then return end

local lombok_jar = lang.resolve_lombok_jar()
local java_exe = lang.resolve_java_executable()
local cmd = { "jdtls", "--java-executable=" .. java_exe, "--jvm-arg=--add-modules=java.compiler,jdk.compiler" }
if lombok_jar then table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar) end

local config = {
  cmd = cmd,
  root_dir = root_dir,
  init_options = {
    bundles = lang.resolve_jdtls_bundles(),
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
  },
  settings = {
    java = {
      eclipse = { downloadSources = true },
      maven = { downloadSources = true },
      references = { includeDecompiledSources = true },
      contentProvider = { preferred = "fernflower" },
      implementationsCodeLens = { enabled = true },
      referencesCodeLens = { enabled = true },
      inlayHints = { parameterNames = { enabled = "all" } },
      signatureHelp = { enabled = true },
      format = {
        settings = {
          url = "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
          profile = "GoogleStyle",
        },
      },
      configuration = {
        updateBuildConfiguration = "interactive",
        runtimes = lang.resolve_java_home() and {
          {
            name = "JavaSE-21",
            path = lang.resolve_java_home(),
            default = true,
          },
        } or nil,
      },
    },
  },
  flags = {
    allow_incremental_sync = true,
  },
  on_attach = function(_, bufnr)
    local jdtls_dap = require "jdtls.dap"
    jdtls.setup_dap { hotcodereplace = "auto" }
    jdtls_dap.setup_dap_main_class_configs()

    local refresh_state = vim.g._java_project_refresh_state or {}
    vim.g._java_project_refresh_state = refresh_state
    if root_dir and not refresh_state[root_dir] then
      refresh_state[root_dir] = true
      vim.defer_fn(function()
        pcall(jdtls.update_project_config)
      end, 3000)
    end

    local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc }) end
    map("<leader>jo", jdtls.organize_imports, "Java organize imports")
    map("<leader>jv", jdtls.extract_variable, "Java extract variable")
    map("<leader>jc", jdtls.extract_constant, "Java extract constant")
    map("<leader>jt", jdtls.test_nearest_method, "Java test nearest method")
    map("<leader>jT", jdtls.test_class, "Java test class")
    map("<leader>ju", jdtls.update_project_config, "Java update project config")
    map("<leader>jr", function() vim.cmd "JdtUpdateDebugConfig" end, "Java refresh debug config")
  end,
}

config.workspace_dir = lang.java_workspace_dir(root_dir)

jdtls.start_or_attach(config)
