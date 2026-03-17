# system configuration
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
autoload -Uz compinit
autoload -Uz vcs_info
compinit -u

setopt prompt_subst

if [[ -f "$HOME/.shell_common" ]]; then
	source "$HOME/.shell_common"
fi

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ':%b%c%u'
zstyle ':vcs_info:git:*' actionformats ':%b|%a%c%u'
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

# alias configuration
# fzf configuration
if command -v fzf > /dev/null 2>&1; then
	eval "$(fzf --zsh)"
	export FZF_DEFAULT_OPTS='--bind ctrl-j:down,ctrl-k:up'
fi

# tmux configuration
# if [[ -z ${TMUX} ]]; then
# 	TMUX_SESSION_NAME="dev"
# 	tmux attach-session -t ${TMUX_SESSION_NAME} || tmux new-session -t ${TMUX_SESSION_NAME}
# fi
