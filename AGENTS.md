# Agent Instructions

This repository is the source of truth for personal dotfiles, package bootstrap scripts, the global Codex instruction mirror, and shared skills. Keep changes scoped; inspect tracked and live copies before changing mirrored assets.

## Sync boundaries

- `bootstrap.sh` syncs the repository into `$HOME`, excluding `.git/`, `.github/`, `.agents/`, `.codex/skills/`, `.codex/config.toml`, `.docker/`, `.orbstack/`, `dockerfiles/`, `bootstrap.sh`, `pacman.sh`, `brew.sh`, `Brewfile`, `README.md`, root `/AGENTS.md`, `LICENSE-MIT.txt`, and `.DS_Store`.
- `.codex/AGENTS.md` is included in the main sync and mirrors `~/.codex/AGENTS.md`.
- `.codex/skills/` is synced separately as an authoritative mirror: tracked files overwrite or add files, and local-only files are removed by default. `--preserve-local-skills` opts out; `.system/` and `codex-primary-runtime/` remain protected.
- `.docker/daemon.json` is the tracked Docker engine configuration. It is applied to OrbStack with `bootstrap.sh --apply-orbstack-docker` or manually to the engine-specific path. `dockerfiles/` is repository-only and is not copied to `$HOME`.

## Source of truth

| Concern | Source |
| --- | --- |
| macOS packages | `Brewfile`; required taps stay in `brew.sh` |
| Arch packages | `pacman.sh` `packages` array |
| Dotfile sync | `bootstrap.sh` |
| Global Codex instructions | `.codex/AGENTS.md` ↔ `~/.codex/AGENTS.md` |
| Shared skills | `.codex/skills/` ↔ `~/.codex/skills/` |
| Docker daemon | `.docker/daemon.json` |
| Docker images | `dockerfiles/<image>/Dockerfile` and its README |

## Commands

| Task | Command |
| --- | --- |
| Preview sync | `bash ./bootstrap.sh --dry-run` |
| Apply sync with backup | `bash ./bootstrap.sh --force --backup` |
| Apply OrbStack Docker config | `bash ./bootstrap.sh --force --backup --apply-orbstack-docker` |
| Check/preview Homebrew | `HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file Brewfile`; `bash ./brew.sh --dry-run` |
| Shell checks | `bash -n bootstrap.sh brew.sh pacman.sh`; `shellcheck bootstrap.sh brew.sh pacman.sh`; `shfmt -d -i 4 -ci bootstrap.sh brew.sh pacman.sh`; `zsh -n .zshrc` |
| Build cross-compile image | `docker build -t go-cross-compile-builder:latest ./dockerfiles/go-cross-compile-builder/` |
| Smoke-test image | `docker run --rm go-cross-compile-builder:latest go version` |

## Workflows

### Package lists

- Keep only manually selected formulae/casks in `Brewfile`; compare direct formulae with `brew leaves` and casks with `brew list --cask`. Do not copy `brew list --formula` wholesale: it includes dependencies.
- Keep required non-core taps in `brew.sh`'s `required_taps` array. `brew.sh` synchronizes non-core taps to that list and removes unlisted taps with `brew untap --force`; it also removes formulae/casks not in `Brewfile` by default. Use `--dry-run` before applying package or Tap changes; `--no-cleanup` opts out of package removal.
- Treat `pacman.sh`'s `packages` array as the direct Arch install list.
- `brew.sh` does not update Homebrew metadata unless `--update` is passed.
- `pacman.sh` installs with `pacman`; a full `-Syu` requires `--upgrade-system`.

### Mirrored Codex assets

- Edit tracked copies under `.codex/`, preview with `--dry-run`, apply with `bash ./bootstrap.sh --force`, then verify with `cmp` or an rsync checksum comparison. Use `--preserve-local-skills` only for a machine that intentionally keeps local-only skills.
- Keep `.codex/config.toml` local-only; it may contain machine-specific MCP configuration and is intentionally excluded from the main sync.
- Keep each skill self-contained: update its `SKILL.md` and referenced scripts, templates, references, notices, or licenses together.
- Keep repeatable procedures with their owning project, script, or skill, and discard temporary state and secrets.
- `--delete-skills` is retained for compatibility; default skill sync is authoritative, while `.system/` and `codex-primary-runtime/` remain protected.

### Docker

- Edit the relevant `Dockerfile` directly. For `go-cross-compile-builder`, `GO_VERSION` defaults to `latest`, `BASE_IMAGE` to `debian:jessie-slim` (glibc 2.19), and `IMAGE_PLATFORM` to `linux/amd64`; the Linaro toolchains require an x86_64 build platform.
- For OrbStack engine changes, use `bootstrap.sh --apply-orbstack-docker` or `orb config docker`, then restart with `orb restart docker` and verify with `docker info --format '{{json .RegistryConfig.Mirrors}}'`.

## Verification

- Run the relevant command above after changing packages, sync boundaries, mirrored assets, or Docker files.
- CI checks `bootstrap.sh`, `brew.sh`, `pacman.sh`, and `.zshrc`; update `.github/workflows/shell-checks.yml` when adding another maintained root shell script.
- A local syntax/build check does not prove target-device, external-service, or production behavior.

## Pitfalls

- Root `AGENTS.md` is excluded from sync; edit `.codex/AGENTS.md` for global Codex instructions.
- `brew list --formula` includes dependencies; use `brew leaves` when maintaining `Brewfile`.
- `.codex/skills` mirror cleanup protects `.system/` and `codex-primary-runtime/`; use `--preserve-local-skills` to retain other local-only skills.
- Do not change the cross-compile image platform without replacing the x86_64-only Linaro toolchains.

## Maintenance

Update this file when the sync boundary, package workflow, skill-sync model, Docker workflow, or verification commands change.
