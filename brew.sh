#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew > /dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	if ! grep -Fq 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zshrc"; then
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
	fi

	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! brew tap | grep -qx "beeftornado/rmtree"; then
	brew tap beeftornado/rmtree
fi

formulae=(
	"git"
	"vim"
	"rsync"
	"go"
	"rust"
	"python"
	"lua"
	"node"
	"kubectl"
	"ffmpeg"
	"ripgrep"
	"lazygit"
	"tmux"
	"protobuf"
	"upx"
	"inetutils"
)

casks=(
	"clash-verge-rev"
	"apifox"
	"wechat"
	"wechatwork"
	"dingtalk"
	"google-chrome"
	"windows-app"
	"navicat-premium"
	"openvpn-connect"
	"orbstack"
	"sunloginclient"
	"tencent-lemon"
	"termius"
	"wpsoffice"
	"xmind"
	"codex"
	"codex-app"
	"chatgpt"
	"proxyman"
	"postman"
	"visual-studio-code"
	"pixpin"
	"balenaetcher"
	"openspec"
)

for formula in "${formulae[@]}"; do
	if ! brew list --versions "$formula" > /dev/null 2>&1; then
		brew install "$formula"
	fi
done

for cask in "${casks[@]}"; do
	if ! brew list --cask --versions "$cask" > /dev/null 2>&1; then
		brew install --cask "$cask"
	fi
done
