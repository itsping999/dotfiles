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

Preview changes without writing files:

```bash
bash ./bootstrap.sh --dry-run
```

Back up overwritten files:

```bash
bash ./bootstrap.sh --force --backup
```

## Package Install

macOS:

```bash
bash ./brew.sh
```

- Auto-installs Homebrew if missing.
- Installs missing formulae and casks defined in `Brewfile`.
- Use `--upgrade` to upgrade packages that are already installed.
- Use `--dry-run` to preview package actions.

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
- `.gitconfig`: Git defaults, identity, and URL rewrites
- `.gitmessage`: Angular/Conventional Commits template
- `.config/git/ignore`: global Git ignore rules
- `Brewfile`: macOS Homebrew package manifest
- `bootstrap.sh`: syncs dotfiles into `$HOME`
- `brew.sh`: macOS package bootstrap
- `pacman.sh`: Arch package bootstrap

## Notes

- `bootstrap.sh` excludes package manifests/scripts, README, Git metadata, CI metadata, and `.DS_Store`.
- Shell `path`/`fpath` entries are de-duplicated by zsh.
- Default editor is `vim`.

## CI

Shell scripts are checked in GitHub Actions with:

- `shellcheck`
- `shfmt -d`
- `bash -n`
