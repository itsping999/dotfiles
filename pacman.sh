#!/usr/bin/env bash
set -euo pipefail

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
    podman
    podman-compose
    ffmpeg
    git-lfs
)

if ! command -v yay >/dev/null 2>&1; then
    echo "yay is required but not installed; install yay first." >&2
    exit 1
fi

sudo pacman -Syu --needed --noconfirm "${packages[@]}"
