#!/usr/bin/env bash
set -euo pipefail

formulae=(
    git
    vim
    rsync
    go
    rust
    python
    lua
    node
    kubectl
    ffmpeg
    ripgrep
    lazygit
    tmux
    protobuf
    upx
    inetutils
)

casks=(
    clash-verge-rev
    apifox
    wechat
    wechatwork
    dingtalk
    google-chrome
    windows-app
    navicat-premium
    openvpn-connect
    awesun
    tencent-lemon
    termius
    wpsoffice
    xmind
    codex-app
    chatgpt
    proxyman
    postman
    visual-studio-code
    pixpin
    balenaetcher
    orbstack
)

if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_BIN="$(command -v brew || true)"
if [[ -z "$BREW_BIN" ]]; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        BREW_BIN="/opt/homebrew/bin/brew"
    elif [[ -x /usr/local/bin/brew ]]; then
        BREW_BIN="/usr/local/bin/brew"
    else
        echo "brew installed but executable not found in PATH" >&2
        exit 1
    fi
fi

eval "$("$BREW_BIN" shellenv)"

for formula in "${formulae[@]}"; do
    if ! brew list --versions "$formula" >/dev/null 2>&1; then
        brew install "$formula"
    fi
done

for cask in "${casks[@]}"; do
    if ! brew list --cask --versions "$cask" >/dev/null 2>&1; then
        brew install --cask "$cask"
    fi
done
