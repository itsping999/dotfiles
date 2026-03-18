#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

git -C "$SCRIPT_DIR" pull --ff-only

do_it() {
    rsync --exclude ".git/" \
        --exclude "bootstrap.sh" \
        --exclude "pacman.sh" \
        --exclude "brew.sh" \
        --exclude "README.md" \
        --exclude "LICENSE-MIT.txt" \
        -avh --no-perms "$SCRIPT_DIR"/ "$HOME"
    echo "dotfiles synced to $HOME"
}

if [[ "${1:-}" == "--force" || "${1:-}" == "-f" ]]; then
    do_it
else
    read -r -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        do_it
    fi
fi

unset -f do_it
