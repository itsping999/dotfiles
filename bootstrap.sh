#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
FORCE=false
BACKUP=false
DELETE_SKILLS=false

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [--force] [--dry-run] [--backup] [--delete-skills]

Sync dotfiles and shared Codex skills into $HOME.

Options:
  -f, --force          Skip confirmation
  -n, --dry-run        Show files that would be synced without changing anything
  -b, --backup         Back up overwritten files with a timestamp suffix
  --delete-skills      Delete files in ~/.codex/skills that are not tracked in this repo
  -h, --help           Show this help
EOF
}

do_it() {
    local -a rsync_args=(
        --exclude ".git/"
        --exclude ".github/"
        --exclude ".agents/"
        --exclude ".codex/skills/"
        --exclude "dockerfiles/"
        --exclude "bootstrap.sh"
        --exclude "pacman.sh"
        --exclude "brew.sh"
        --exclude "Brewfile"
        --exclude "README.md"
        --exclude "AGENTS.md"
        --exclude "LICENSE-MIT.txt"
        --exclude ".DS_Store"
        -avh
        --no-perms
    )

    if [[ "$DRY_RUN" == true ]]; then
        rsync_args+=(--dry-run)
    fi

    if [[ "$BACKUP" == true ]]; then
        rsync_args+=(--backup --suffix=".bak-$(date +%Y%m%d%H%M%S)")
    fi

    rsync "${rsync_args[@]}" "$SCRIPT_DIR"/ "$HOME"/

    # Sync .codex/skills/ into ~/.codex/skills/.
    # Default: repo files overwrite local, new repo files are added, local-only files are preserved.
    # With --delete: mirror mode, removes local-only files (except .system/ and codex-primary-runtime/).
    local skills_src="$SCRIPT_DIR/.codex/skills/"
    local skills_dst="$HOME/.codex/skills/"
    local -a skills_rsync_args=(
        -avh
        --no-perms
        --exclude ".DS_Store"
        --exclude "__pycache__/"
        --exclude "*.pyc"
        --exclude ".system/"
        --exclude "codex-primary-runtime/"
    )
    [[ "$DELETE_SKILLS" == true ]] && skills_rsync_args+=(--delete)
    [[ "$DRY_RUN" == true ]] && skills_rsync_args+=(--dry-run)
    [[ "$BACKUP" == true ]] && skills_rsync_args+=(--backup --suffix=".bak-$(date +%Y%m%d%H%M%S)")
    mkdir -p "$skills_dst"
    rsync "${skills_rsync_args[@]}" "$skills_src" "$skills_dst"

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
        --delete-skills)
            DELETE_SKILLS=true
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
