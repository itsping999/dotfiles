# system configuration.

export TERM="xterm-256color"

if [[ -z ${TMUX} ]]; then
	cd ~

	export GOPROXY="https://goproxy.cn,direct"
	export GO111MODULE=on
	export GOPATH="$HOME/go"
	export GOBIN="$HOME/go/bin"
	export PATH="$GOPATH:$GOBIN:$PATH"

	# export all_proxy="socks5://172.29.248.135:7890"
	# export ALL_PROXY="socks5://172.29.248.135:7890"
	# export LC_ALL="en_US.UTF-8"
	# export LC_CTYPE="en_US.UTF-8"
	export LANG="en_US.UTF-8"
	export LANGUAGE="en_US.UTF-8"
	export HISTSIZE=1000
	export HISTFILESIZE=2000
	export HISTCONTROL=ignoredups:erasedups

	shopt -s histappend
	set bell-style none

	if [[ "$OSTYPE" == "darwin"* && -f /opt/homebrew/bin/brew ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -f /etc/arch-release && -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	fi
fi

if command -v git > /dev/null 2>&1; then
	export PS1="\[\e[33m\][\u@\h \w\[\e[33m\]\$(_git_ps1)\[\e[33m\]]\$\[\e[m\] "
else
	export PS1="\[\e[33m\][\u@\h \w]\\$\[\e[m\] "
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

# git configuration
if command -v git > /dev/null 2>&1; then
	# function to show git branch and status
	_git_ps1() {
		git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
		if [ -n "$git_branch" ]; then
			git_status=$(git status --porcelain 2>/dev/null)
			if [ -n "$git_status" ]; then
				echo ":$git_branch*"
			else
				echo ":$git_branch"
			fi
		fi
	}
	
	# function to complete git branch
	_git_branch_completion() {
	    local branches cur
	    cur="${COMP_WORDS[COMP_CWORD]}"
	    branches=$(git branch --all | grep -v '\->' | sed 's/remotes\/origin\///' | sed 's/^[ *]*//')
	    COMPREPLY=($(compgen -W "${branches}" -- "${cur}"))
	}
	
	complete -F _git_branch_completion g switch
	complete -F _git_branch_completion g checkout
	complete -F _git_branch_completion g merge
	complete -F _git_branch_completion g rebase
	complete -F _git_branch_completion g pull
	complete -F _git_branch_completion g push
	complete -F _git_branch_completion git switch
	complete -F _git_branch_completion git checkout
	complete -F _git_branch_completion git merge
	complete -F _git_branch_completion git rebase
	complete -F _git_branch_completion git pull
	complete -F _git_branch_completion git push
fi

# fzf configuration
eval "$(fzf --bash)"

if command -v fzf > /dev/null 2>&1; then
	export FZF_DEFAULT_OPTS='--bind ctrl-j:down,ctrl-k:up'
fi

# edior configuration
if command -v vim > /dev/null 2>&1; then
	export EDITOR=/usr/sbin/nvim
fi


# kubectl configuration
if command -v kubectl > /dev/null 2>&1; then

	_kubectl_pod_complete() {
		local cur pods
		cur="${COMP_WORDS[COMP_CWORD]}"
		pods=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" --all-namespaces)
		COMPREPLY=($(compgen -W "${pods}" -- "${cur}"))
	}

	_kubectl_deployment_complete() {
		local cur deployments
		cur="${COMP_WORDS[COMP_CWORD]}"
		deployments=$(kubectl get deployments --no-headers -o custom-columns=":metadata.name" --all-namespaces)
		COMPREPLY=($(compgen -W "${deployments}" -- "${cur}"))
	}
	
	complete -F _kubectl_pod_complete kubectl logs -f
	complete -F _kubectl_pod_complete kubectl delete pods
	complete -F _kubectl_pod_complete kubectl describe pods

	complete -F _kubectl_deployment_complete kubectl delete deployments
	complete -F _kubectl_deployment_complete kubectl describe deployments
	complete -F _kubectl_deployment_complete kubectl edit deployments
	complete -F _kubectl_deployment_complete kubectl scale deployments
fi

# tmux configuration
if [[ -z ${TMUX} ]]; then
	TMUX_SESSION_NAME="dev"
	tmux attach-session -t ${TMUX_SESSION_NAME} || tmux new-session -t ${TMUX_SESSION_NAME}
fi

