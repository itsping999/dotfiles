#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMULAE_FILE="$SCRIPT_DIR/packages/brew-formulae.txt"
CASKS_FILE="$SCRIPT_DIR/packages/brew-casks.txt"

if [[ ! -f "$FORMULAE_FILE" ]]; then
    echo "missing package list: $FORMULAE_FILE" >&2
    exit 1
fi

if [[ ! -f "$CASKS_FILE" ]]; then
    echo "missing package list: $CASKS_FILE" >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_shellenv_line="eval \"\$(/opt/homebrew/bin/brew shellenv)\""

    if [[ ! -f "$HOME/.zshrc" ]] || ! grep -Fq "$brew_shellenv_line" "$HOME/.zshrc"; then
        echo "$brew_shellenv_line" >>"$HOME/.zshrc"
    fi
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

if ! brew tap | grep -qx "beeftornado/rmtree"; then
    brew tap beeftornado/rmtree
fi

while IFS= read -r formula || [[ -n "$formula" ]]; do
    [[ -z "$formula" || "${formula:0:1}" == "#" ]] && continue
    if ! brew list --versions "$formula" >/dev/null 2>&1; then
        brew install "$formula"
    fi
done <"$FORMULAE_FILE"

while IFS= read -r cask || [[ -n "$cask" ]]; do
    [[ -z "$cask" || "${cask:0:1}" == "#" ]] && continue
    if ! brew list --cask --versions "$cask" >/dev/null 2>&1; then
        brew install --cask "$cask"
    fi
done <"$CASKS_FILE"
