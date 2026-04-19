local M = {}

local uv = vim.uv
local fn = vim.fn
local api = vim.api

local template_dir = vim.fn.stdpath "config" .. "/templates"
local pending_templates = {}

local function read_file(path)
  local fd = uv.fs_open(path, "r", 420)
  if not fd then return nil end
  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil
  end
  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data
end

local function write_lines(bufnr, text)
  local lines = vim.split(text or "", "\n", { plain = true })
  if #lines > 0 and lines[#lines] == "" then table.remove(lines, #lines) end
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

local function normalize_path(path)
  if not path or path == "" then return "" end
  return vim.fs.normalize(fn.fnamemodify(path, ":p"))
end

local function is_empty_buffer(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  if #lines == 0 then return true end
  if #lines == 1 and lines[1] == "" then return true end
  return false
end

local function normalize_package_part(value)
  value = (value or ""):gsub("[^%w_]", "_")
  value = value:gsub("^[%d_]+", "")
  if value == "" then return "main" end
  return value
end

local function go_package_name(path)
  local dir = vim.fs.dirname(path)
  local base = vim.fs.basename(dir)
  if base == nil or base == "" then return "main" end
  if base == "cmd" then
    local parent = vim.fs.basename(vim.fs.dirname(dir))
    return normalize_package_part(parent)
  end
  return normalize_package_part(base)
end

local function java_package_name(path)
  local normalized = vim.fs.normalize(path)
  local markers = { "/src/main/java/", "/src/test/java/", "/src/integrationTest/java/", "/src/main/kotlin/", "/src/test/kotlin/" }
  for _, marker in ipairs(markers) do
    local idx = normalized:find(marker, 1, true)
    if idx then
      local tail = normalized:sub(idx + #marker)
      local dir = vim.fs.dirname(tail)
      if dir and dir ~= "." then return (dir:gsub("/", ".")) end
      return ""
    end
  end
  return ""
end

local function include_guard(path)
  local normalized = vim.fs.normalize(path)
  local identity = normalized
  for _, marker in ipairs { "/include/", "/src/" } do
    local idx = normalized:find(marker, 1, true)
    if idx then
      identity = normalized:sub(idx + 1)
      break
    end
  end
  if identity == normalized then
    local root = vim.fs.root(path, { ".git", "compile_commands.json", "CMakeLists.txt", "Makefile" })
    if root then identity = vim.fs.relpath(root, normalized) or normalized end
  end
  identity = identity:upper()
  identity = identity:gsub("[^A-Z0-9]", "_")
  identity = identity:gsub("_+", "_")
  identity = identity:gsub("^_", "")
  identity = identity:gsub("_$", "")
  return identity .. "_"
end

local function namespace_name(path)
  local dir = vim.fs.dirname(path)
  local base = vim.fs.basename(dir)
  if not base or base == "" or base == "." then return "" end
  if base == "include" or base == "src" then return "" end
  local ns = base:gsub("[^%w_]", "_")
  ns = ns:gsub("^[%d_]+", "")
  return ns
end

local function pascal_case(name)
  local parts = vim.split(name or "", "[^%w]+", { trimempty = true })
  if #parts == 0 then return "Main" end
  for i, part in ipairs(parts) do
    parts[i] = part:sub(1, 1):upper() .. part:sub(2)
  end
  local joined = table.concat(parts, "")
  joined = joined:gsub("^[%d]+", "")
  if joined == "" then return "Main" end
  return joined
end

local function class_name(path)
  local name = fn.fnamemodify(path, ":t:r")
  return pascal_case(name)
end

local function project_name(path)
  local normalized = vim.fs.normalize(path)
  for _, marker in ipairs { "/src/main/java/", "/src/test/java/", "/src/integrationTest/java/", "/src/main/kotlin/", "/src/test/kotlin/" } do
    local idx = normalized:find(marker, 1, true)
    if idx then
      local base = vim.fs.basename(normalized:sub(1, idx - 1))
      if base and base ~= "" then
        base = base:gsub("[^%w]+", ".")
        base = base:gsub("%.+", ".")
        base = base:gsub("^%.", "")
        base = base:gsub("%.$", "")
        if base ~= "" then return base end
      end
    end
  end

  local root = vim.fs.root(path, { ".git", "go.mod", "pom.xml", "build.gradle", "build.gradle.kts", "CMakeLists.txt" })
  local base = root and vim.fs.basename(root) or vim.fs.basename(vim.fs.dirname(path))
  base = (base or "app"):gsub("[^%w]+", ".")
  base = base:gsub("%.+", ".")
  base = base:gsub("^%.", "")
  base = base:gsub("%.$", "")
  return base ~= "" and base or "app"
end

local function go_test_name(path)
  local stem = fn.fnamemodify(path, ":t:r")
  stem = stem:gsub("_test$", "")
  return pascal_case(stem)
end

local function go_example_name(path)
  local stem = fn.fnamemodify(path, ":t:r")
  stem = stem:gsub("_test$", "")
  return pascal_case(stem)
end

local function is_java_test_path(path)
  local normalized = vim.fs.normalize(path)
  return normalized:find("/src/test/java/", 1, true) ~= nil or normalized:find("/src/integrationTest/java/", 1, true) ~= nil
end

local function template_candidates(path)
  local ext = fn.fnamemodify(path, ":e")
  local stem = fn.fnamemodify(path, ":t:r")
  local file_name = fn.fnamemodify(path, ":t")
  local candidates = {}

  if ext == "go" then
    if stem == "main" then
      candidates = {
        { name = "go-main", label = "Go Main" },
        { name = "go-file", label = "Go File" },
        { name = "go-interface", label = "Go Interface" },
      }
    elseif stem:match "_test$" then
      candidates = {
        { name = "go-test", label = "Go Test" },
        { name = "go-benchmark", label = "Go Benchmark" },
        { name = "go-example-test", label = "Go Example Test" },
        { name = "go-file", label = "Go File" },
      }
    else
      candidates = {
        { name = "go-file", label = "Go File" },
        { name = "go-interface", label = "Go Interface" },
      }
    end
  elseif ext == "java" then
    if file_name == "package-info.java" then
      candidates = {
        { name = "java-package-info", label = "Java Package Info" },
      }
    elseif file_name == "module-info.java" then
      candidates = {
        { name = "java-module-info", label = "Java Module Info" },
      }
    else
      candidates = {
        { name = "java-class", label = "Java Class" },
        { name = "java-abstract-class", label = "Java Abstract Class" },
        { name = "java-interface", label = "Java Interface" },
        { name = "java-enum", label = "Java Enum" },
        { name = "java-record", label = "Java Record" },
        { name = "java-annotation", label = "Java Annotation" },
      }
      if is_java_test_path(path) or stem:match "Test$" then table.insert(candidates, 2, { name = "java-junit-test", label = "Java JUnit Test" }) end
    end
  elseif ext == "cpp" or ext == "cc" or ext == "cxx" then
    candidates = stem == "main" and {
      { name = "cpp-main", label = "C++ Main" },
      { name = "cpp-source", label = "C++ Source" },
      { name = "cpp-class-source", label = "C++ Class Source" },
    } or {
      { name = "cpp-source", label = "C++ Source" },
      { name = "cpp-class-source", label = "C++ Class Source" },
      { name = "cpp-main", label = "C++ Main" },
    }
  elseif ext == "h" or ext == "hpp" or ext == "hh" or ext == "hxx" then
    candidates = {
      { name = "cpp-header", label = "C++ Header" },
      { name = "cpp-class-header", label = "C++ Class Header" },
      { name = "cpp-header-only", label = "C++ Header-only Class" },
    }
  end

  return candidates
end

local function vars_for(path)
  local package_name = java_package_name(path)
  local namespace = namespace_name(path)
  local class = class_name(path)
  return {
    FILE_NAME = fn.fnamemodify(path, ":t"),
    FILE_STEM = fn.fnamemodify(path, ":t:r"),
    NAME = class,
    CLASS_NAME = class,
    PACKAGE_NAME = package_name,
    PACKAGE_DECL = package_name ~= "" and ("package " .. package_name .. ";\n\n") or "",
    JAVA_MODULE_NAME = project_name(path),
    GO_PACKAGE = go_package_name(path),
    GO_TEST_NAME = go_test_name(path),
    GO_EXAMPLE_NAME = go_example_name(path),
    INCLUDE_GUARD = include_guard(path),
    NAMESPACE = namespace,
    NAMESPACE_BEGIN = namespace ~= "" and ("namespace " .. namespace .. " {\n\n") or "",
    NAMESPACE_END = namespace ~= "" and ("\n} // namespace " .. namespace .. "\n") or "",
    YEAR = os.date "%Y",
    DATE = os.date "%Y-%m-%d",
  }
end

local function render(text, vars)
  return (text:gsub("%${([A-Z0-9_]+)}", function(key)
    local value = vars[key]
    if value == nil then return "" end
    return value
  end))
end

local function find_template(path_or_name)
  local direct = template_dir .. "/" .. path_or_name
  if uv.fs_stat(direct) then return direct end
  local with_suffix = direct .. ".tmpl"
  if uv.fs_stat(with_suffix) then return with_suffix end
  return nil
end

local function pick_item(items, prompt, on_choice)
  if #items == 0 then return end
  if #items == 1 or #api.nvim_list_uis() == 0 then
    on_choice(items[1])
    return
  end
  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item) return item.label or item.name or tostring(item) end,
  }, on_choice)
end

local function start_new_file(kind, items)
  pick_item(items, kind .. " template", function(choice)
    if not choice then return end
    vim.schedule(function()
      local default_name = choice.default_name or ""
      local path = fn.input(kind .. " file path: ", default_name, "file")
      if not path or path == "" then return end
      local absolute = normalize_path(path)
      local dir = vim.fs.dirname(absolute)
      if dir and dir ~= "" then fn.mkdir(dir, "p") end
      pending_templates[absolute] = choice.name
      vim.cmd("edit " .. fn.fnameescape(absolute))
    end)
  end)
end

function M.available_templates()
  local ret = {}
  local iter = uv.fs_scandir(template_dir)
  if not iter then return ret end
  while true do
    local name, kind = uv.fs_scandir_next(iter)
    if not name then break end
    if kind == "file" and name:sub(-5) == ".tmpl" then table.insert(ret, name:sub(1, -6)) end
  end
  table.sort(ret)
  return ret
end

function M.apply(bufnr, template_name)
  bufnr = bufnr or api.nvim_get_current_buf()
  local path = api.nvim_buf_get_name(bufnr)
  if path == "" then return false, "buffer has no file name" end
  if not is_empty_buffer(bufnr) then return false, "buffer is not empty" end

  local template_path = find_template(template_name)
  if not template_path then return false, "template not found: " .. template_name end

  local text = read_file(template_path)
  if not text then return false, "failed to read template: " .. template_path end

  local rendered = render(text, vars_for(path))
  write_lines(bufnr, rendered)
  api.nvim_buf_set_option(bufnr, "modified", true)
  return true
end

function M.apply_default(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local path = api.nvim_buf_get_name(bufnr)
  if path == "" or not is_empty_buffer(bufnr) then return end

  local normalized = normalize_path(path)
  local pending = pending_templates[normalized]
  if pending then
    pending_templates[normalized] = nil
    local ok, err = M.apply(bufnr, pending)
    if not ok and err then vim.notify(err, vim.log.levels.WARN) end
    return
  end

  local candidates = template_candidates(path)
  if #candidates == 0 then return end
  if #candidates == 1 or vim.fn.has "nvim-0.10" == 0 or #vim.api.nvim_list_uis() == 0 then
    M.apply(bufnr, candidates[1].name)
    return
  end

  vim.schedule(function()
    if not api.nvim_buf_is_valid(bufnr) or not is_empty_buffer(bufnr) then return end
    vim.ui.select(candidates, {
      prompt = "New file template",
      format_item = function(item) return item.label end,
    }, function(choice)
      if not choice then return end
      local ok, err = M.apply(bufnr, choice.name)
      if not ok and err then vim.notify(err, vim.log.levels.WARN) end
    end)
  end)
end

function M.pick(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()
  local items = {}
  for _, name in ipairs(M.available_templates()) do
    table.insert(items, { name = name, label = name })
  end
  pick_item(items, "File template", function(choice)
    if not choice then return end
    local ok, err = M.apply(bufnr, choice.name)
    if not ok and err then vim.notify(err, vim.log.levels.WARN) end
  end)
end

function M.new_java()
  start_new_file("Java", {
    { name = "java-class", label = "Java Class", default_name = "src/main/java/Main.java" },
    { name = "java-abstract-class", label = "Java Abstract Class", default_name = "src/main/java/BaseThing.java" },
    { name = "java-interface", label = "Java Interface", default_name = "src/main/java/Port.java" },
    { name = "java-enum", label = "Java Enum", default_name = "src/main/java/Status.java" },
    { name = "java-record", label = "Java Record", default_name = "src/main/java/ThingRecord.java" },
    { name = "java-annotation", label = "Java Annotation", default_name = "src/main/java/MyAnnotation.java" },
    { name = "java-junit-test", label = "Java JUnit Test", default_name = "src/test/java/MainTest.java" },
    { name = "java-package-info", label = "Java Package Info", default_name = "src/main/java/package-info.java" },
    { name = "java-module-info", label = "Java Module Info", default_name = "src/main/java/module-info.java" },
  })
end

function M.new_go()
  start_new_file("Go", {
    { name = "go-file", label = "Go File", default_name = "pkg/example/example.go" },
    { name = "go-main", label = "Go Main", default_name = "cmd/app/main.go" },
    { name = "go-interface", label = "Go Interface", default_name = "pkg/example/port.go" },
    { name = "go-test", label = "Go Test", default_name = "pkg/example/example_test.go" },
    { name = "go-benchmark", label = "Go Benchmark", default_name = "pkg/example/example_test.go" },
    { name = "go-example-test", label = "Go Example Test", default_name = "pkg/example/example_test.go" },
  })
end

function M.new_cpp()
  start_new_file("C++", {
    { name = "cpp-source", label = "C++ Source", default_name = "src/example.cpp" },
    { name = "cpp-class-source", label = "C++ Class Source", default_name = "src/example.cpp" },
    { name = "cpp-main", label = "C++ Main", default_name = "src/main.cpp" },
    { name = "cpp-header", label = "C++ Header", default_name = "include/example.h" },
    { name = "cpp-class-header", label = "C++ Class Header", default_name = "include/example.h" },
    { name = "cpp-header-only", label = "C++ Header-only Class", default_name = "include/example.h" },
  })
end

function M.setup()
  local group = api.nvim_create_augroup("user_file_templates", { clear = true })
  api.nvim_create_autocmd("BufNewFile", {
    group = group,
    callback = function(args) require("config.file_templates").apply_default(args.buf) end,
  })

  api.nvim_create_user_command("FileTemplatePick", function() require("config.file_templates").pick(0) end, {
    desc = "Pick and apply a file template",
  })

  api.nvim_create_user_command("FileTemplateApply", function(opts)
    local ok, err = require("config.file_templates").apply(0, opts.args)
    if not ok and err then vim.notify(err, vim.log.levels.WARN) end
  end, {
    nargs = 1,
    complete = function() return require("config.file_templates").available_templates() end,
    desc = "Apply a file template by name",
  })

  api.nvim_create_user_command("NewJava", function() require("config.file_templates").new_java() end, {
    desc = "Create a new Java file from a template",
  })

  api.nvim_create_user_command("NewGo", function() require("config.file_templates").new_go() end, {
    desc = "Create a new Go file from a template",
  })

  api.nvim_create_user_command("NewCpp", function() require("config.file_templates").new_cpp() end, {
    desc = "Create a new C++ file from a template",
  })
end

return M
