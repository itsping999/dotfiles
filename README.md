# dotfiles

Lean personal dotfiles for macOS and Arch Linux.

## Quick Start

```bash
git clone git@github.com:itsping999/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./bootstrap.sh
```

Use `--force` to skip confirmation:

```bash
bash ./bootstrap.sh --force
```

## Package Install

macOS:

```bash
bash ./brew.sh
```

- Auto-installs Homebrew if missing.
- Installs formulae and casks defined directly in `brew.sh`.

Arch Linux:

```bash
bash ./pacman.sh
```

- Requires `yay` to be preinstalled.
- Installs packages defined directly in `pacman.sh`.

## Config Files

- `.zshrc`: shell config
- `.vimrc`: Vim config
- `.tmux.conf`: tmux config
- `bootstrap.sh`: syncs dotfiles into `$HOME`
- `brew.sh`: macOS package bootstrap
- `pacman.sh`: Arch package bootstrap

## Notes

- Shell configuration is single-file (`.zshrc`), no cross-file sourcing.
- Default editor is `vim`.

## CI

Shell scripts are checked in GitHub Actions with:

- `shellcheck`
- `shfmt -d`
