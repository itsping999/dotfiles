#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.agents/skills"
TARGET_DIR="$HOME/.agents/skills"
DRY_RUN=false
DELETE=false

usage() {
    cat <<'EOF'
Usage: skills.sh [--dry-run] [--delete]

Sync tracked agent skills into ~/.agents/skills.
By default, files that exist only in ~/.agents/skills are preserved.

Options:
  -n, --dry-run   Show files that would be synced without changing anything
  --delete        Delete files in ~/.agents/skills that are not tracked here
  -h, --help      Show this help
EOF
}

while (($#)); do
    case "$1" in
        -n | --dry-run)
            DRY_RUN=true
            ;;
        --delete)
            DELETE=true
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
    --exclude ".DS_Store"
)

if [[ "$DELETE" == true ]]; then
    rsync_args+=(--delete)
fi

if [[ "$DRY_RUN" == true ]]; then
    rsync_args+=(--dry-run)
fi

rsync "${rsync_args[@]}" "$SOURCE_DIR"/ "$TARGET_DIR"/

if [[ "$DRY_RUN" == true ]]; then
    echo "dry run complete; no skills changed"
else
    if [[ "$DELETE" == true ]]; then
        echo "skills synced to $TARGET_DIR with deletion enabled"
    else
        echo "skills synced to $TARGET_DIR; local-only skills preserved"
    fi
fi
