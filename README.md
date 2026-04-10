# dotfiles

Personal macOS dotfiles managed with `yadm`.

This repo keeps the durable, shareable parts of my environment: shell config, editor config, terminal/UI config, and a few developer-tool defaults. Secrets, machine-local overrides, caches, and app runtime state stay out of version control.

## What this repo manages

### Shell
- `~/.zshrc`
- `~/.zshenv`
- `~/.bash_profile`
- `~/.bashrc`
- `~/.profile`

### Editor / IDE
- `~/.config/nvim/`
- `~/.ideavimrc`
- `~/.config/zed/custom.css`
- `~/.config/zed/keymap.json`

### Terminal / UI
- `~/.tmux.conf.local`
- `~/.vimrc`
- `~/.config/starship.toml`
- `~/.config/yazi/keymap.toml`
- `~/.yabairc`
- `~/.skhdrc`

### Developer tooling
- `~/.gitconfig`
- `~/.config/git/ignore`
- `~/.config/goose/config.yaml`
- `~/.config/pip/pip.conf`

## What is intentionally excluded

These stay local-only and should not be committed:

- `~/.zshrc.local`
- `~/.ssh/`
- `~/.gnupg/`
- `~/.android/`
- `~/.config/raycast/config.json`
- `~/.config/spotify-tui/client.yml`
- `.cursor/`
- caches, histories, swap files, and tool runtime state

The current exclusion policy lives in `~/.gitignore`.

## Bootstrap on a new machine

### 1. Install the base tools

At minimum install:

- `git`
- `yadm`
- `zsh`

On macOS, I usually also need these soon after bootstrap:

- `neovim`
- `tmux`
- `starship`
- `yazi`
- `jq`
- `yabai`
- `skhd`
- `pyenv`
- `nvm`
- `rustup` / `cargo`
- `gvm`
- `fastfetch`

### 2. Clone the repo with yadm

SSH:

```bash
yadm clone git@github.com:YxYL6125/dotfiles.git
```

HTTPS:

```bash
yadm clone https://github.com/YxYL6125/dotfiles.git
```

Useful checks after clone:

```bash
yadm list
yadm status
```

### 3. Create local-only overrides

`~/.zshrc` will source `~/.zshrc.local` if it exists.

Create that file on every machine and keep secrets or machine-specific overrides there:

```bash
touch ~/.zshrc.local
chmod 600 ~/.zshrc.local
```

Typical things to put in `~/.zshrc.local`:

- API keys
- tokens
- private PATH additions
- machine-specific SDK paths
- internal-only endpoints or hostnames

Example:

```bash
export ANTHROPIC_API_KEY="<your-key>"
# export JAVA_HOME="/path/to/your/jdk"
# export SOME_INTERNAL_ENDPOINT="https://example.internal"
```

Do not put secrets back into tracked files such as `~/.zshrc`.

### 4. Review machine-specific settings

This repo is personal and not fully portable as-is. After clone, review and adapt:

- `~/.zshrc`
  - hardcoded `JAVA_HOME`
  - Go proxy / private module settings
  - local/internal tools such as `.bytebm`, `openclaw`, `antigravity`
- `~/.gitconfig`
  - git identity
  - internal URL rewrite rules
- `~/.config/pip/pip.conf`
  - internal Python package index
- `~/.config/nvim/init.lua`
  - Python host path

If a setting is only needed on one machine, prefer putting it in `~/.zshrc.local` instead of editing tracked files.

### 5. Complete tool-specific setup

#### Neovim

This repo includes a personal AstroNvim-based setup in `~/.config/nvim/`.

Minimum assumptions:

- `nvim >= 0.10`
- `git`
- `make`
- `python3`
- Java 21
- Go toolchain

First launch:

```bash
nvim
```

That first launch should bootstrap plugins and related tooling. See `~/.config/nvim/README.md` for more notes.

#### tmux

This repo only manages `~/.tmux.conf.local`.

The main tmux config comes from a separate `oh-my-tmux` checkout in `~/.tmux`, with `~/.tmux.conf` symlinked to `~/.tmux/.tmux.conf`.

Install it like this:

```bash
git clone --single-branch https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
cp ~/.tmux/.tmux.conf.local ~/.tmux.conf.local
```

Then reconcile any local changes with the version tracked in this repo.

#### yabai / skhd

These configs assume macOS plus both tools installed:

- `~/.yabairc`
- `~/.skhdrc`

Also expected:

- `jq`
- the usual macOS permissions for window management / accessibility
- for yabai scripting addition usage: `sudo yabai --load-sa`

One macOS setting I rely on:

- disable "Automatically rearrange Spaces based on most recent use"

## Required tools and environment assumptions

Some parts of shell startup assume these tools or files already exist:

- zinit (auto-installed by `~/.zshrc` if missing)
- `~/.gvm/scripts/gvm`
- `~/.nvm/nvm.sh`
- `~/.pyenv`
- `~/.cargo/env`
- `~/.local/bin/env`
- `yazi`
- `fastfetch`

If a fresh machine is missing some of these, shell startup may be partial or noisy until they are installed or the relevant lines are adjusted.

## Daily yadm workflow

```bash
yadm status
yadm diff
yadm add <path>
yadm commit
yadm push
```

When adding new config:

1. Check whether it contains secrets, tokens, app state, or generated files.
2. If yes, keep it local-only or add ignore rules first.
3. Prefer portable defaults in tracked files and machine-specific overrides in `~/.zshrc.local`.

## Verification checklist

After migration to a new machine, I usually verify:

```bash
yadm list
yadm status
zsh -i -c exit
nvim
python3 --version
go version
java -version
jq --version
tmux -V
yabai --version
skhd --version
```

If all of those behave as expected, the machine is usually in a good state.
