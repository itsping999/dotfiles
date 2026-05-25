#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.agents/skills"
TARGET_DIR="$HOME/.agents/skills"
DRY_RUN=false

usage() {
    cat <<'EOF'
Usage: skills.sh [--dry-run]

Sync tracked agent skills into ~/.agents/skills.

Options:
  -n, --dry-run   Show files that would be synced without changing anything
  -h, --help      Show this help
EOF
}

while (($#)); do
    case "$1" in
        -n | --dry-run)
            DRY_RUN=true
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

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "skills source directory not found: $SOURCE_DIR" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"

rsync_args=(
    -avh
    --delete
    --exclude ".DS_Store"
)

if [[ "$DRY_RUN" == true ]]; then
    rsync_args+=(--dry-run)
fi

rsync "${rsync_args[@]}" "$SOURCE_DIR"/ "$TARGET_DIR"/

if [[ "$DRY_RUN" == true ]]; then
    echo "dry run complete; no skills changed"
else
    echo "skills synced to $TARGET_DIR"
fi
