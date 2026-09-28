[[ -o interactive ]] || return 0

typeset -U path fpath

export LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

if [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
	eval "$(/usr/local/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [[ -r "$HOME/.acme.sh/acme.sh.env" ]]; then
	source "$HOME/.acme.sh/acme.sh.env"
fi

export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="${GOBIN:-$GOPATH/bin}"

path=("$HOME/.local/bin" "$GOBIN" $path)

if command -v brew >/dev/null 2>&1; then
	BREW_PREFIX="$(brew --prefix)"
	if [[ -d "$BREW_PREFIX/share/zsh/site-functions" ]]; then
		fpath=("$BREW_PREFIX/share/zsh/site-functions" $fpath)
	fi
	if [[ -d "$BREW_PREFIX/opt/mysql-client/bin" ]]; then
		path=("$BREW_PREFIX/opt/mysql-client/bin" $path)
	fi
	unset BREW_PREFIX
fi

export PATH

autoload -Uz compinit
compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"

setopt prompt_subst

alias ll="ls -l"
alias l="ls -l"
alias la="ls -al"
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"
alias g="git"
alias lg="lazygit"

if [[ -z "${EDITOR:-}" ]] && command -v vim >/dev/null 2>&1; then
	export EDITOR="vim"
fi
if [[ -z "${VISUAL:-}" ]] && [[ -n "${EDITOR:-}" ]]; then
	export VISUAL="$EDITOR"
fi

if [[ -n "${EDITOR:-}" ]]; then
	alias vi="$EDITOR"
fi

git_prompt() {
	local branch git_state
	branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || return
	git_state=$(git status --porcelain 2>/dev/null) || return
	if [[ -n "$git_state" ]]; then
		printf ":%s*" "$branch"
	else
		printf ":%s" "$branch"
	fi
}

if command -v scutil >/dev/null 2>&1; then
	PROMPT_HOSTNAME="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
else
	PROMPT_HOSTNAME="$(hostname -s 2>/dev/null || hostname)"
fi
PROMPT='%F{yellow}[%n@${PROMPT_HOSTNAME} %~$( \
  git_prompt \
)]%f
$ '

export HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=20000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS
setopt INC_APPEND_HISTORY
setopt HIST_VERIFY
setopt NO_BEEP

if command -v fzf >/dev/null 2>&1; then
	eval "$(fzf --zsh)"
	export FZF_DEFAULT_OPTS='--bind ctrl-j:down,ctrl-k:up'
fi

if [[ -r "$HOME/.zshrc.local" ]]; then
	source "$HOME/.zshrc.local"
fi
