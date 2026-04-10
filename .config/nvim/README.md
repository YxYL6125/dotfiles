# Neovim config

AstroNvim v5 based personal config for daily Java, Go, and Python work.

What is inside

- AstroNvim + lazy.nvim plugin management
- Java: nvim-jdtls, jdtls, java-debug-adapter, java-test
- Go: gopls, gofumpt, goimports, delve
- Python: pyright, black, isort, ruff, mypy, debugpy, nvim-dap-python
- Navigation: Harpoon, Flash, Telescope FZF
- Debugging: nvim-dap + nvim-dap-ui
- UI: astrodark theme, smear-cursor

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

Active keymaps to remember

LSP

- `gd` definition
- `gi` implementation
- `gr` references
- `gy` type definition
- `K` hover
- `<leader>cr` rename
- `<leader>ca` code action

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
- Go: `<leader>gt` debug current test, `<leader>gT` debug last test, `<leader>gi` organize imports
- Python: `<leader>pr` debug method, `<leader>pR` debug class, `<leader>pf` debug selection, `<leader>pi` organize imports

Notes

- Java uses dedicated `nvim-jdtls` startup from `ftplugin/java.lua`, not generic `lspconfig` attach.
- Go uses `gopls`, `goimports`, `gofumpt`, and `dlv` from `~/.local/bin` on this machine because Mason's latest Go tool packages are not compatible with the local Go 1.18 toolchain.
- Python DAP prefers Mason's `debugpy` virtualenv and falls back to system Python.
- Java runtime config prefers `JAVA_HOME` / `JDK21_HOME` and falls back to the local JDK 21 path if present.
- Template placeholder files still exist only where harmless; active behavior lives in `lua/plugins/*.lua`.
