#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
FORCE=false
BACKUP=false
DELETE_SKILLS=true
APPLY_ORBSTACK_DOCKER=false

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [--force] [--dry-run] [--backup] [--preserve-local-skills] [--apply-orbstack-docker]

Sync dotfiles and shared agent skills into $HOME.

Options:
  -f, --force          Skip confirmation
  -n, --dry-run        Show files that would be synced without changing anything
  -b, --backup         Back up overwritten files with a timestamp suffix
  --preserve-local-skills
                       Keep files in ~/.agents/skills that are not tracked in this repo
  --delete-skills      Deprecated compatibility flag; mirror mode is already the default
  --apply-orbstack-docker
                       Apply .docker/daemon.json to OrbStack and restart its Docker engine
  -h, --help           Show this help
EOF
}

do_it() {
    local -a rsync_args=(
        --exclude ".git/"
        --exclude ".github/"
        --exclude ".agents/skills/"
        --exclude ".agents/config.toml"
        --exclude ".codex/"
        --exclude ".docker/"
        --exclude ".orbstack/"
        --exclude "dockerfiles/"
        --exclude "bootstrap.sh"
        --exclude "pacman.sh"
        --exclude "brew.sh"
        --exclude "Brewfile"
        --exclude "README.md"
        --exclude "/AGENTS.md"
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

    # Sync .agents/skills/ into ~/.agents/skills/.
    # Mirror mode: repo files overwrite local, new repo files are added, and local-only files
    # are removed (except .system/ and codex-primary-runtime/).
    local skills_src="$SCRIPT_DIR/.agents/skills/"
    local skills_dst="$HOME/.agents/skills/"
    local -a skills_rsync_args=(
        -avh
        --no-perms
        --no-owner
        --no-group
        --exclude ".DS_Store"
        --exclude "__pycache__/"
        --exclude "*.pyc"
        --exclude ".system/"
        --exclude "codex-primary-runtime/"
    )
    [[ "$DELETE_SKILLS" == true ]] && skills_rsync_args+=(--delete)
    [[ "$DRY_RUN" == true ]] && skills_rsync_args+=(--dry-run)
    local skills_backup_dir
    skills_backup_dir="$HOME/.agents/skills-backups/$(date +%Y%m%d%H%M%S)"
    if [[ "$BACKUP" == true ]]; then
        skills_rsync_args+=(--backup --backup-dir="$skills_backup_dir")
    fi
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$skills_dst"
        [[ "$BACKUP" == true ]] && mkdir -p "$skills_backup_dir"
    fi
    rsync "${skills_rsync_args[@]}" "$skills_src" "$skills_dst"

    if [[ "$APPLY_ORBSTACK_DOCKER" == true ]]; then
        local orbstack_docker_dst="$HOME/.orbstack/config/docker.json"
        if [[ "$DRY_RUN" == true ]]; then
            echo "would sync $SCRIPT_DIR/.docker/daemon.json -> $orbstack_docker_dst"
            echo "would run: orb restart docker"
        else
            if ! command -v orb >/dev/null 2>&1; then
                echo "orb is required for --apply-orbstack-docker" >&2
                exit 1
            fi

            mkdir -p "$(dirname "$orbstack_docker_dst")"
            if [[ "$BACKUP" == true ]]; then
                rsync -avh --no-perms --backup --suffix=".bak-$(date +%Y%m%d%H%M%S)" \
                    "$SCRIPT_DIR/.docker/daemon.json" "$orbstack_docker_dst"
            else
                rsync -avh --no-perms \
                    "$SCRIPT_DIR/.docker/daemon.json" "$orbstack_docker_dst"
            fi
            orb restart docker
        fi
    fi

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
        --preserve-local-skills)
            DELETE_SKILLS=false
            ;;
        --delete-skills)
            DELETE_SKILLS=true
            ;;
        --apply-orbstack-docker)
            APPLY_ORBSTACK_DOCKER=true
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
