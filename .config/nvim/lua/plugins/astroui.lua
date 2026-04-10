local transparent_groups = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "SignColumn",
  "EndOfBuffer",
  "WinSeparator",
  "VertSplit",
  "StatusLine",
  "StatusLineNC",
  "TabLine",
  "TabLineFill",
  "TabLineSel",
  "Pmenu",
  "PmenuSbar",
  "Folded",
  "WinBar",
  "WinBarNC",
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeEndOfBuffer",
  "NeoTreeWinSeparator",
  "NeoTreeVertSplit",
  "NeoTreeFloatBorder",
  "NeoTreeTitleBar",
}

---@type LazySpec
return {
  {
    "AstroNvim/astrotheme",
    optional = true,
    opts = {
      style = {
        transparent = true,
        neotree = false,
      },
      highlights = {
        global = {
          modify_hl_groups = function(hl, c)
            for _, group in ipairs(transparent_groups) do
              hl[group] = hl[group] or {}
              hl[group].bg = c.none
            end

            hl.FloatBorder.fg = c.ui.border
            hl.FloatTitle.fg = c.ui.title
            hl.PmenuThumb = { fg = c.none, bg = c.ui.scrollbar, blend = 0 }
            hl.NeoTreeCursorLine = { bg = c.ui.selection, bold = true }
          end,
        },
      },
    },
  },
  {
    "AstroNvim/astroui",
    version = false,
    ---@type AstroUIOpts
    opts = {
      colorscheme = "astrodark",
      highlights = {
        astrodark = {
          CursorLineNr = { fg = "#ffd173", bold = true },
        },
      },
      icons = {
        LSPLoading1 = "⠋",
        LSPLoading2 = "⠙",
        LSPLoading3 = "⠹",
        LSPLoading4 = "⠸",
        LSPLoading5 = "⠼",
        LSPLoading6 = "⠴",
        LSPLoading7 = "⠦",
        LSPLoading8 = "⠧",
        LSPLoading9 = "⠇",
        LSPLoading10 = "⠏",
      },
    },
  },
}
