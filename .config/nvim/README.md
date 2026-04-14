# Neovim config

AstroNvim v5 based personal config for daily Java, Go, and Python work.

What is inside

- AstroNvim + lazy.nvim plugin management
- Java: nvim-jdtls, jdtls, java-debug-adapter, java-test
- Go: gopls, delve
- Python: pyright, black, isort, ruff, mypy, debugpy, nvim-dap-python
- Navigation: Harpoon, Flash, Telescope FZF
- Debugging: nvim-dap + nvim-dap-ui
- UI: astrodark theme

Quick start

```sh
cp -R ~/.config/nvim ~/.config/nvim.backup.manual 2>/dev/null || true
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
```

Open Neovim once and let lazy/mason install packages:

```sh
nvim
```

Important dependencies

- Neovim >= 0.10
- git
- make
- python3
- Java 21
- Go toolchain

Optional environment variables

- `JAVA_HOME` or `JDK21_HOME`: preferred Java runtime path for jdtls

Git workflow

Recommended split of responsibility:

- `<leader>gg`: main entry for day-to-day git work. Opens LazyGit in AstroNvim's known-good ToggleTerm float path.
- `<leader>ge`: changed-files/status picker when you want a fast file-oriented jump list instead of a full TUI.
- gitsigns: in-buffer hunk operations while editing (`<leader>gs`, `<leader>gr`, `<leader>gp`, `[g`, `]g`).
- Diffview: structured review and history (`<leader>gD`, `<leader>gH`, `<leader>gF`, `<leader>gv`, `<leader>gq`).
- Neogit: editor-native status/commit flow (`<leader>gn`, `<leader>gc`).
- Conflict resolution: `<leader>gm` for quickfix list, then `co` / `ct` / `cb` / `c0` and `[x` / `]x` inside conflicted buffers.
- Blame/archaeology: `<leader>gB` toggles inline blame, `<leader>gV` shows a popup of commits touching the current line.

Suggested daily flow:

1. `<leader>gg` for status/stage/commit/branch/push.
2. While editing, use gitsigns for hunk-level stage/reset/preview.
3. Use `<leader>ge` to jump among changed files.
4. Use `<leader>gD` for current diff review, `<leader>gF` for current-file history review, `<leader>gv` for current branch vs base-branch review, `<leader>gH` for repo history.
5. Use `<leader>go` to open the current repo/file/selection in the remote forge.

Active keymaps to remember

LSP

- `gd` definition
- `gi` implementation
- `gr` references
- `gy` type definition
- `K` hover
- `<leader>cr` rename
- `<leader>ca` smart code actions
- `<M-CR>` / `<A-CR>` smart code actions (Alt+Enter, if your terminal sends it)

Harpoon

- `<leader>ha` add file
- `<leader>hh` toggle list
- `<leader>h1` .. `<leader>h5` jump to file

Debugging

- `<F5>` continue/start
- `<F6>` run last config
- `<F10>` step over
- `<F11>` step into
- `<F12>` step out
- `<leader>db` toggle breakpoint
- `<leader>dB` conditional breakpoint
- `<leader>dr` restart
- `<leader>dx` terminate
- `<leader>de` eval under cursor

Language extras

- Java: `<leader>jo` organize imports, `<leader>jt` test method, `<leader>jT` test class, `<leader>ju` reload project config
- Go: `<leader>dt` debug current test, `<leader>dT` debug last test, `<leader>oi` organize imports
- Python: `<leader>pr` debug method, `<leader>pR` debug class, `<leader>pf` debug selection, `<leader>pi` organize imports

Notes

- Java uses dedicated `nvim-jdtls` startup from `ftplugin/java.lua`, not generic `lspconfig` attach.
- Go uses `gopls` and `dlv` from `~/.local/bin` on this machine because Mason's latest Go tool packages are not compatible with the local Go 1.18 toolchain.
- Python DAP prefers Mason's `debugpy` virtualenv and falls back to system Python.
- Java runtime config prefers `JAVA_HOME` / `JDK21_HOME` and falls back to the local JDK 21 path if present.
- Dead template leftovers have been removed; active behavior lives in `lua/plugins/*.lua`.
