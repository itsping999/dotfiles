fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit
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

git_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null
}

git_marks() {
  local s
  s=$(git status --porcelain 2>/dev/null) || return
  [[ "$s" == *[MADRCU]* ]] && printf '+'
  [[ "$s" == *'??'* || "$s" == *' M'* || "$s" == *' D'* ]] && printf '*'
}

setopt PROMPT_SUBST
PROMPT='%F{yellow}[%n@%m %~$( \
  b=$(git_branch); \
  [[ -n "$b" ]] && printf ":%s%s" "$b" "$(git_marks)" \
)]%f
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
