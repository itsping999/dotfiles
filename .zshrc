# system configuration.
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit
compinit -u
setopt prompt_subst
export TERM="xterm-256color"

if [[ -z ${TMUX} ]]; then
	cd ~

	export GOPROXY="https://goproxy.cn,direct"
	export GO111MODULE=on
	export GOPATH="$HOME/go"
	export GOBIN="$HOME/go/bin"
	export PATH="$GOPATH:$GOBIN:$PATH"

	export ALL_PROXY="socks5://127.0.0.1:7890"
	export HTTP_PROXY="socks5://127.0.0.1:7890"
	export HTTPS_PROXY="socks5://127.0.0.1:7890"
	# export LC_ALL="en_US.UTF-8"
	# export LC_CTYPE="en_US.UTF-8"
	export LANG="en_US.UTF-8"
	export LANGUAGE="en_US.UTF-8"
	export HISTSIZE=1000
	export SAVEHIST=2000

	setopt HIST_IGNORE_DUPS
	setopt HIST_IGNORE_ALL_DUPS
	setopt HIST_EXPIRE_DUPS_FIRST
	setopt HIST_SAVE_NO_DUPS
	setopt HIST_VERIFY
	setopt APPEND_HISTORY
	setopt NO_BEEP

	if [[ "$OSTYPE" == "darwin"* && -f /opt/homebrew/bin/brew ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -f /etc/arch-release && -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	fi
fi


if command -v git > /dev/null 2>&1; then
	# function to show git branch and status
	_git_ps1() {
		local git_branch git_status
		git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
		if [[ -n "$git_branch" ]]; then
			git_status=$(git status --porcelain 2>/dev/null)
			if [[ -n "$git_status" ]]; then
				echo ":${git_branch}*"
			else
				echo ":${git_branch}"
			fi
		fi
	}

	PROMPT='%F{yellow}[%n@%m %~$(_git_ps1)]%f
$ '
else
	PROMPT='%F{yellow}[%n@%m %~]%f
$ '
fi

# alias configuration.
alias ll="ls -l"
alias l="ls -l"
alias la="ls -al"
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"
alias g="git"
alias vi="vim"
alias vim="vim"
alias lg="lazygit"

# fzf configuration
if command -v fzf > /dev/null 2>&1; then
	eval "$(fzf --zsh)"
	export FZF_DEFAULT_OPTS='--bind ctrl-j:down,ctrl-k:up'
fi

# edior configuration
if command -v vim > /dev/null 2>&1; then
	export EDITOR=/usr/sbin/nvim
fi

# tmux configuration
# if [[ -z ${TMUX} ]]; then
# 	TMUX_SESSION_NAME="dev"
# 	tmux attach-session -t ${TMUX_SESSION_NAME} || tmux new-session -t ${TMUX_SESSION_NAME}
# fi
