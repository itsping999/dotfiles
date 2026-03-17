# dotfiles

Personal shell/editor/tooling configuration for macOS and Arch Linux.

## Quick Start

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
bash ./bootstrap.sh
```

Use `--force` to skip confirmation:

```bash
bash ./bootstrap.sh --force
```

## Package Setup

macOS (Homebrew):

```bash
bash ./brew.sh
```

Package lists are maintained in:

- `packages/brew-formulae.txt`
- `packages/brew-casks.txt`

Arch Linux (pacman + yay):

```bash
bash ./pacman.sh
```

Package list is maintained in:

- `packages/pacman-packages.txt`

## CI

GitHub Actions validates shell scripts with:

- `shellcheck`
- `shfmt -d`

Workflow file:

- `.github/workflows/shell-checks.yml`

## Shell Notes

- Shared shell config is in `.shell_common` and loaded by both `.bashrc` and `.zshrc`.
- `AUTO_TMUX=1` enables auto attach/create tmux session (`dev`) in Bash startup.
- Default editor prefers `nvim`, then falls back to `vim`.
- `.bashrc` now skips interactive-only prompt/completion setup for non-interactive shells.

## Structure

- `.zshrc` / `.bashrc`: shell-specific behavior
- `.shell_common`: shared env/aliases/editor settings
- `.vimrc`: Vim config
- `.config/nvim`: Neovim Lua config
- `.tmux.conf`: tmux and tpm plugins
- `bootstrap.sh`: sync dotfiles to `$HOME`
- `brew.sh` / `pacman.sh`: package bootstrap scripts

## Safety

`bootstrap.sh` uses `rsync` and will overwrite matching files in your home directory after confirmation.
