#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
FORCE=false
BACKUP=false

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [--force] [--dry-run] [--backup]

Sync dotfiles into $HOME.

Options:
  -f, --force     Skip confirmation
  -n, --dry-run   Show files that would be synced without changing anything
  -b, --backup    Back up overwritten files with a timestamp suffix
  -h, --help      Show this help
EOF
}

do_it() {
    local -a rsync_args=(
        --exclude ".git/"
        --exclude ".github/"
        --exclude "bootstrap.sh" \
        --exclude "pacman.sh" \
        --exclude "brew.sh" \
        --exclude "Brewfile" \
        --exclude "README.md" \
        --exclude "LICENSE-MIT.txt" \
        --exclude ".DS_Store" \
        -avh \
        --no-perms
    )

    if [[ "$DRY_RUN" == true ]]; then
        rsync_args+=(--dry-run)
    fi

    if [[ "$BACKUP" == true ]]; then
        rsync_args+=(--backup --suffix=".bak-$(date +%Y%m%d%H%M%S)")
    fi

    rsync "${rsync_args[@]}" "$SCRIPT_DIR"/ "$HOME"/

    if [[ "$DRY_RUN" == true ]]; then
        echo "dry run complete; no files changed"
    else
        echo "dotfiles synced to $HOME"
    fi
}

while (($#)); do
    case "$1" in
        -f | --force)
            FORCE=true
            ;;
        -n | --dry-run)
            DRY_RUN=true
            ;;
        -b | --backup)
            BACKUP=true
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if [[ "$FORCE" == true || "$DRY_RUN" == true ]]; then
    do_it
else
    read -r -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        do_it
    fi
fi

unset -f do_it
