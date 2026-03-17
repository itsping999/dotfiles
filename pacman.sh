#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages/pacman-packages.txt"

if [[ ! -f "$PACKAGES_FILE" ]]; then
	echo "missing package list: $PACKAGES_FILE" >&2
	exit 1
fi

if ! command -v yay > /dev/null 2>&1; then
	if ! grep -q "^\[archlinuxcn\]" /etc/pacman.conf; then
		sudo bash -c 'echo [archlinuxcn] >> /etc/pacman.conf'
		sudo bash -c 'echo Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch >> /etc/pacman.conf'
	fi

	sudo pacman -Sy
	sudo pacman -S --needed archlinuxcn-keyring yay
fi

packages=()
while IFS= read -r package || [[ -n "$package" ]]; do
	[[ -z "$package" || "${package:0:1}" == "#" ]] && continue
	packages+=("$package")
done < "$PACKAGES_FILE"

sudo pacman -Syu --needed --noconfirm "${packages[@]}"
