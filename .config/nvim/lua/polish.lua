-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

require("config.file_templates").setup()

return {
  -- `plugins` 表格用于添加或覆盖插件的配置
}
