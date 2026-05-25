#!/usr/bin/env bash
set -euo pipefail

BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Brewfile"
DRY_RUN=false
UPGRADE=false

usage() {
    cat <<'EOF'
Usage: brew.sh [--upgrade] [--dry-run]

Install Homebrew packages declared in Brewfile.

Options:
  -u, --upgrade   Upgrade already installed packages
  -n, --dry-run   Show actions without installing or upgrading packages
  -h, --help      Show this help
EOF
}

while (($#)); do
    case "$1" in
        -u | --upgrade)
            UPGRADE=true
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

if ! command -v brew >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "would install Homebrew"
        exit 0
    fi

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

if [[ "$DRY_RUN" == true ]]; then
    echo "would run: brew update"
    if [[ "$UPGRADE" == true ]]; then
        "$BREW_BIN" bundle check --file "$BREWFILE" || true
        echo "would run: brew bundle install --upgrade --file $BREWFILE"
    else
        "$BREW_BIN" bundle check --file "$BREWFILE" || true
        echo "would run: brew bundle install --no-upgrade --file $BREWFILE"
    fi
else
    "$BREW_BIN" update

    if [[ "$UPGRADE" == true ]]; then
        "$BREW_BIN" bundle install --upgrade --file "$BREWFILE"
    else
        "$BREW_BIN" bundle install --no-upgrade --file "$BREWFILE"
    fi
fi
