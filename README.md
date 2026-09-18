# dotfiles

Lean personal dotfiles for macOS and Arch Linux.

## Quick Start

~~~bash
git clone git@github.com:itsping999/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash ./bootstrap.sh
~~~

Use --force to skip confirmation:

~~~bash
bash ./bootstrap.sh --force
~~~

Preview changes without writing files:

~~~bash
bash ./bootstrap.sh --dry-run
~~~

Back up overwritten files:

~~~bash
bash ./bootstrap.sh --force --backup
~~~

Apply the tracked Docker engine configuration to OrbStack:

~~~bash
bash ./bootstrap.sh --force --backup --apply-orbstack-docker
~~~

## Package Install

macOS:

~~~bash
bash ./brew.sh
~~~

- Auto-installs Homebrew if missing.
- Installs missing formulae and casks defined in Brewfile.
- Synchronizes non-core Homebrew taps to `brew.sh`'s `required_taps` list and removes unlisted taps with their tap-owned packages.
- Removes formulae and casks not declared in Brewfile by default; use --no-cleanup to keep them.
- Homebrew dependencies are preserved automatically; Brewfile should contain direct packages, not every entry from `brew list --formula`.
- Use --upgrade to upgrade packages that are already installed.
- Use --update when Homebrew metadata should be updated first.
- Use --dry-run to preview package actions.

Arch Linux:

~~~bash
bash ./pacman.sh
~~~

- Installs packages with pacman; yay is not required.
- Use --dry-run to print the command without changing the system.
- Use --upgrade-system to opt into a full pacman -Syu.

## Config Files

- .zshrc: shell config
- .vimrc: Vim config
- .tmux.conf: tmux config
- .gitconfig: Git defaults and URL rewrites
- .gitconfig.local.example: private Git identity template
- .config/git/ignore: global Git ignore rules
- .docker/daemon.json: Docker engine mirrors, BuildKit, log rotation, and address pools
- .codex/skills: tracked shared Codex skills
- .codex/AGENTS.md: tracked global Codex instructions
- Brewfile: macOS Homebrew package manifest
- bootstrap.sh: syncs dotfiles into the home directory
- brew.sh: macOS package bootstrap
- pacman.sh: Arch package bootstrap

## Notes

- bootstrap.sh excludes package manifests/scripts, the root AGENTS.md, README, Git metadata, CI metadata, tracked skills, .codex/config.toml, Docker engine configuration, and .DS_Store; .codex/AGENTS.md remains included and syncs to ~/.codex/AGENTS.md. The Codex config stays local because it may contain machine-specific MCP settings.
- bootstrap.sh --apply-orbstack-docker copies .docker/daemon.json to ~/.orbstack/config/docker.json and restarts OrbStack's Docker engine. It is opt-in because restarting the engine can interrupt running containers.
- bootstrap.sh mirrors .codex/skills by deleting local-only files, while preserving Codex system skill directories such as .system/; use --preserve-local-skills to opt out.
- Shell path/fpath entries are de-duplicated by zsh.
- .zshrc preserves machine-specific additions through ~/.zshrc.local.
- The current machine's .bashrc and .zprofile remain local because they contain private or application-managed settings; only safe guards are maintained there.
- Git identity is loaded from ~/.gitconfig.local. Create it from .gitconfig.local.example before making commits on a fresh machine.
- If Vim-Plug is not installed, install it and restore plugins with:

  ~~~bash
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  vim +PlugInstall +qall
  ~~~

## OrbStack Docker Configuration

OrbStack does not use ~/.docker/daemon.json as its Docker engine configuration. The supported configuration file is ~/.orbstack/config/docker.json.

Interactive editing:

~~~bash
orb config docker
~~~

Applying this repository's configuration:

~~~bash
bash ./bootstrap.sh --force --backup --apply-orbstack-docker
~~~

Manual application:

~~~bash
mkdir -p ~/.orbstack/config
rsync -avh --backup --suffix=".bak-$(date +%Y%m%d%H%M%S)" \
    .docker/daemon.json ~/.orbstack/config/docker.json
orb restart docker
~~~

Verify the active engine rather than only the file:

~~~bash
docker context show
docker info --format 'mirrors={{json .RegistryConfig.Mirrors}} logging={{.LoggingDriver}}'
~~~

Do not expose the Docker engine over TCP without TLS and client authentication. Review registry mirrors and address pools for the current network before applying them.

## CI

Shell scripts are checked in GitHub Actions with:

- shellcheck
- shfmt -d
- bash -n
- zsh -n .zshrc
