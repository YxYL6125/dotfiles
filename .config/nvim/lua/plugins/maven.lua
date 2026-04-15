local function maven()
  package.loaded["config.maven"] = nil
  local mod = require "config.maven"
  mod.setup()
  return mod
end

local keymaps = {
  ["<leader>mm"] = { "menu", "Maven actions" },
  ["<leader>ml"] = { "run_lifecycle", "Maven lifecycle goal" },
  ["<leader>mL"] = { "run_lifecycle_select_module", "Maven lifecycle goal (select module)" },
  ["<leader>mp"] = { "run_plugin_goal", "Maven plugin goal" },
  ["<leader>mP"] = { "run_plugin_goal_select_module", "Maven plugin goal (select module)" },
  ["<leader>mt"] = { "run_thrift_goal", "Maven thrift goal" },
  ["<leader>mr"] = { "run_custom", "Maven custom command" },
  ["<leader>mR"] = { "run_custom_select_module", "Maven custom command (select module)" },
  ["<leader>mf"] = { "run_favorites", "Maven favorite goal" },
  ["<leader>mF"] = { "run_favorites_select_module", "Maven favorite goal (select module)" },
  ["<leader>mh"] = { "show_history", "Maven recent history" },
  ["<leader>mA"] = { "favorite_add_prompt", "Maven add favorite" },
  ["<leader>md"] = { "favorite_remove", "Maven remove favorite" },
}

return {
  {
    "AstroNvim/astrocore",
    optional = true,
    init = function() maven().setup() end,
    opts = function(_, opts)
      opts.mappings = opts.mappings or {}
      opts.mappings.n = opts.mappings.n or {}
      opts.mappings.n["<leader>m"] = vim.tbl_get(opts, "_map_sections", "m") or { desc = "Maven" }

      for lhs, spec in pairs(keymaps) do
        local method, desc = spec[1], spec[2]
        opts.mappings.n[lhs] = {
          function() maven()[method]() end,
          desc = desc,
        }
      end
    end,
  },
}
