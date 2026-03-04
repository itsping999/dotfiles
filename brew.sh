#!/usr/bin/env bash

if ! command -v brew > /dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
	eval "$(/opt/homebrew/bin/brew shellenv)"

	brew tap beeftornado/rmtree
fi

packages=(
	"clash-verge-rev"
	"git"
	"vim"
	"rsync"
	"golang"
	"rust"
	"python"
	"lua"
	"nodejs"
	"kubectl"
	"ffmpeg"
	"ripgrep"
	"apifox"
	"wechat"
	"wechatwork"
	"dingtalk"
	"google-chrome"
	"windows-app"
	"navicat-premium"
	"openvpn-connect"
	"drawio"
	"orbstack"
	"sunloginclient"
	"tencent-lemon"
	"termius"
	"wpsoffice"
	"xmind"
	"lazygit"
	"tmux"
	"codex"
	"codex-app"
	"chatgpt"
	"proxyman"
	"postman"
	"wpsoffice"
	"visual-studio-code"
	"pixpin"
	"protobuf"
	"upx"
	"balenaEtcher"
	"telnet"
)

package_list=$(echo "${packages[@]}" | tr ' ' ' ')

brew install $package_list
