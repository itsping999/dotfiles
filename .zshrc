fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit
autoload -Uz vcs_info
compinit -u

setopt prompt_subst

export TERM="xterm-256color"

export GOPROXY="https://goproxy.cn,direct"
export GO111MODULE=on
export GOPATH="$HOME/go"
export GOBIN="$HOME/go/bin"

case ":$PATH:" in
	*":$GOBIN:"*) ;;
	*) export PATH="$GOBIN:$PATH" ;;
esac

case ":$PATH:" in
	*":$GOPATH:"*) ;;
	*) export PATH="$GOPATH:$PATH" ;;
esac

export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"

if [[ "$OSTYPE" == "darwin"* ]] && [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /etc/arch-release ]] && [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

alias ll="ls -l"
alias l="ls -l"
alias la="ls -al"
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"
alias g="git"
alias lg="lazygit"

if command -v vim > /dev/null 2>&1; then
	export EDITOR="vim"
	export VISUAL="vim"
fi

if [[ -n "${EDITOR:-}" ]]; then
	alias vi="$EDITOR"
fi

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ':%b%c%u'
zstyle ':vcs_info:git:*' actionformats ':%b%c%u'
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' stagedstr '+'

precmd() { vcs_info }

PROMPT='%F{yellow}[%n@%m %~${vcs_info_msg_0_}]%f
$ '

export HISTSIZE=10000
export SAVEHIST=20000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS
setopt APPEND_HISTORY
setopt HIST_VERIFY
setopt NO_BEEP

if command -v fzf > /dev/null 2>&1; then
	eval "$(fzf --zsh)"
	export FZF_DEFAULT_OPTS='--bind ctrl-j:down,ctrl-k:up'
fi
