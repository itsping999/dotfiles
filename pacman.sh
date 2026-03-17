#!/usr/bin/env bash
set -euo pipefail

if ! command -v yay > /dev/null 2>&1; then
	if ! grep -q "^\[archlinuxcn\]" /etc/pacman.conf; then
		sudo bash -c 'echo [archlinuxcn] >> /etc/pacman.conf'
		sudo bash -c 'echo Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch >> /etc/pacman.conf'
	fi

	sudo pacman -Sy
	sudo pacman -S --needed archlinuxcn-keyring yay
fi

packages=(
	"rsync"
	"vim"
	"git"
	"go"
	"rust"
	"cargo"
	"python"
	"python-pip"
	"lua"
	"nodejs"
	"npm"
	"gcc"
	"gdb"
	"tmux"
	"make"
	"net-tools"
	"sshpass"
	"protobuf"
	"tcpdump"
	"which"
	"fzf"
	"ripgrep"
	"unzip"
	"kubectl"
	"inetutils"
	"podman"
	"podman-compose"
	"ffmpeg"
	"git-lfs"
)

sudo pacman -Syu --needed --noconfirm "${packages[@]}"
