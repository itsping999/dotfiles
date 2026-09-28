#!/usr/bin/env bash
set -euo pipefail
DRY_RUN=false
UPGRADE_SYSTEM=false

packages=(
    rsync
    vim
    git
    go
    rust
    cargo
    python
    python-pip
    lua
    nodejs
    npm
    gcc
    gdb
    tmux
    make
    net-tools
    sshpass
    protobuf
    tcpdump
    which
    fzf
    ripgrep
    unzip
    kubectl
    inetutils
    docker
    ffmpeg
    git-lfs
    glow
)

usage() {
    cat <<'USAGE'
Usage: pacman.sh [--upgrade-system] [--dry-run]

Install the selected Arch Linux packages.

Options:
  --upgrade-system  Run pacman -Syu before installing packages
  -n, --dry-run     Print the pacman command without changing the system
  -h, --help        Show this help
USAGE
}

while (($#)); do
    case "$1" in
        --upgrade-system)
            UPGRADE_SYSTEM=true
            ;;
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

if [[ ! -f /etc/arch-release ]]; then
    echo "pacman.sh must be run on Arch Linux." >&2
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    echo "pacman is required but not installed." >&2
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required but not installed." >&2
    exit 1
fi

pacman_args=(-S --needed --noconfirm "${packages[@]}")
if [[ "$UPGRADE_SYSTEM" == true ]]; then
    pacman_args=(-Syu --needed --noconfirm "${packages[@]}")
fi

if [[ "$DRY_RUN" == true ]]; then
    printf 'would run: sudo pacman'
    printf ' %q' "${pacman_args[@]}"
    printf '\n'
else
    sudo pacman "${pacman_args[@]}"
fi
