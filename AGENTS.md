# Agent Instructions

## Project Purpose
- This repository is the tracked source for the user's personal dotfiles, package bootstrap scripts, global Codex instruction mirror, and shared Codex skills.
- Treat files here as source-of-truth for repeatable local setup. Live home-directory copies may drift, so inspect both sides before changing synced global Codex assets.

## Project Map
- `bootstrap.sh` syncs dotfiles and shared Codex skills into `$HOME`. It excludes package scripts/manifests, Git metadata, `.agents/`, `.codex/skills/`, README, and `.DS_Store` from the main sync. It also syncs `.codex/skills/` into `~/.codex/skills/`: repo files overwrite local, new repo files are added, local-only files are preserved. Use `--delete-skills` for mirror mode.
- `brew.sh` installs macOS packages from `Brewfile`; it also taps `farion1231/ccswitch` before running `brew bundle`.
- `pacman.sh` installs the Arch Linux package array directly from that script and requires `yay`.
- `.codex/AGENTS.md` is the dotfiles-tracked mirror of the live global Codex instructions, not the project-level instructions for this repo.
- `.codex/skills/` contains tracked shared Codex skills. Each skill's `SKILL.md` is the entrypoint; templates, scripts, references, notices, and licenses under that skill directory travel with it.
- Shell/editor config files such as `.zshrc`, `.vimrc`, `.tmux.conf`, `.gitconfig`, and `.config/git/ignore` are copied to `$HOME` by `bootstrap.sh`.
- `.docker/daemon.json` is the global Docker daemon configuration with China mirror registries, BuildKit, log rotation, and address pool settings.
- `dockerfiles/` is a directory in this repo that maintains Docker image definitions for build and packaging workflows. Each subdirectory contains a `Dockerfile` and its own `README.md`.

## Source Of Truth
| Concern | File/Directory | Notes |
| --- | --- | --- |
| macOS package list | `Brewfile` | Add formulae with `brew "..."` and apps with `cask "..."`; do not list transient dependencies when comparing local state. |
| Homebrew install behavior | `brew.sh` | Keep taps in the `taps` array and package declarations in `Brewfile`. |
| Arch package list | `pacman.sh` | The `packages` array is the install list. The script exits if `yay` is missing. |
| Dotfile sync exclusions | `bootstrap.sh` | Update `rsync_args` when adding repo files that should not be copied into `$HOME`. |
| Shared skill sync | `bootstrap.sh` and `.codex/skills/` | `bootstrap.sh` syncs skills without `--delete` by default (repo overwrites local, adds new, preserves local-only). Use `--delete-skills` for mirror mode, which still excludes `.system/` and `codex-primary-runtime/`. |
| Global Codex instructions | `.codex/AGENTS.md` and `~/.codex/AGENTS.md` | Change both copies when updating global instructions, then verify parity. |
| Tracked shared Codex skills | `.codex/skills/` and `~/.codex/skills/` | Change both live and tracked copies when maintaining shared skills, or edit tracked copy and run `bash ./bootstrap.sh --force` to sync live. |
| Shell CI coverage | `.github/workflows/shell-checks.yml` | CI currently checks `bootstrap.sh`, `brew.sh`, and `pacman.sh`; update the workflow when adding another maintained shell script. |
| Docker daemon config | `.docker/daemon.json` | Global daemon settings; `bootstrap.sh` syncs this into `~/.docker/daemon.json`. Restart Docker after changes. |
| Docker image definitions | `dockerfiles/` | Docker image definitions; each subdirectory is a self-contained image build context with its own `Dockerfile`. |
| Cross-compile builder image | `dockerfiles/cross-compile-builder/` | Go + Linaro ARM/ARM64 C toolchains for CGO cross-compilation on `linux/amd64`. Go version defaults to `latest` and is overridable via `GO_VERSION` build arg. |

## Commands
| Task | Command |
| --- | --- |
| Preview dotfile sync | `bash ./bootstrap.sh --dry-run` |
| Sync dotfiles with backup | `bash ./bootstrap.sh --force --backup` |
| Preview skill sync | `bash ./bootstrap.sh --dry-run` |
| Sync tracked skills to live Codex | `bash ./bootstrap.sh --force` |
| Check Brewfile without upgrades | `brew bundle check --no-upgrade --file Brewfile` |
| Preview Homebrew actions | `bash ./brew.sh --dry-run` |
| Shell syntax check | `bash -n bootstrap.sh brew.sh pacman.sh` |
| Shell lint | `shellcheck bootstrap.sh brew.sh pacman.sh` |
| Shell format check | `shfmt -d -i 4 -ci bootstrap.sh brew.sh pacman.sh` |
| Build cross-compile-builder image | `docker build -t cross-compile-builder ./dockerfiles/cross-compile-builder/` |
| Build with specific Go version | `docker build --build-arg GO_VERSION=1.22.4 -t cross-compile-builder ./dockerfiles/cross-compile-builder/` |
| Docker daemon config check | `docker info --format '{{.RegistryConfig.Mirrors}}'` |

## Common Workflows
### Add Or Remove A Homebrew Item
1. Edit `Brewfile`; keep manually maintained formulae/casks there and do not add dependency-only formulae discovered from `brew list`.
2. For formula comparisons, use `brew leaves` to ignore dependencies. For apps, compare `brew list --cask`.
3. Verify with `brew bundle check --no-upgrade --file Brewfile`. A plain `brew bundle check` may fail because existing packages are outdated.
4. If a new cask needs a tap, add it to `brew.sh`'s `taps` array and re-run `bash ./brew.sh --dry-run`.

### Change Bootstrap Sync Behavior
1. Inspect `bootstrap.sh` before editing so new files land on the intended side of the sync boundary.
2. Keep generated caches, package manifests, scripts, `.codex/skills/`, `.agents/`, and CI metadata out of `$HOME` sync unless the user explicitly wants them copied.
3. Verify with `bash ./bootstrap.sh --dry-run` and the shell checks.

### Maintain Shared Codex Skills
1. Edit the specific skill directory under `.codex/skills/<skill-name>/`.
2. Keep the skill self-contained: update `SKILL.md` plus any referenced `scripts/`, `templates/`, `references/`, `NOTICE`, or `LICENSE` files together.
3. Sync live skills with `bash ./bootstrap.sh --force` unless you deliberately edited `~/.codex/skills/` first; then reconcile the tracked mirror and verify the diff.
4. Use `bash ./bootstrap.sh --dry-run --delete-skills` only to preview destructive mirror cleanup. Do not remove local-only or system skills unless the user explicitly asks.

### Change Global Codex Instructions
1. Edit both `~/.codex/AGENTS.md` and `.codex/AGENTS.md`, or edit one and copy it to the other.
2. Verify parity with `cmp -s ~/.codex/AGENTS.md .codex/AGENTS.md`.
3. Inspect the changed section after syncing so stale or duplicate wording does not remain.

### Build Or Update Docker Images
1. Edit the relevant `Dockerfile` under `dockerfiles/<image-name>/`.
2. For `cross-compile-builder`: the Go version defaults to `latest` (fetched from `go.dev`); override with `GO_VERSION` build arg if a specific version is needed.
3. The base image defaults to `docker.1ms.run/library/debian:bookworm-slim` (China mirror); override with `BASE_IMAGE` build arg if needed.
4. Build and test locally with `docker build -t <image-name> ./dockerfiles/<image-name>/`.
5. For `cross-compile-builder`, verify the image works: `docker run --rm cross-compile-builder go version` and test a cross-compilation target.

### Update Docker Daemon Configuration
1. Edit `.docker/daemon.json`.
2. Run `bash ./bootstrap.sh --dry-run` to verify the file is included in sync.
3. Apply with `bash ./bootstrap.sh --force --backup`.
4. Restart Docker Desktop for changes to take effect. Verify mirrors with `docker info --format '{{.RegistryConfig.Mirrors}}'`.

## Verification
- For shell script changes, run `shellcheck`, `bash -n`, and `shfmt -d -i 4 -ci` on the edited scripts.
- For package manifest changes, run `brew bundle check --no-upgrade --file Brewfile` on macOS. Use `bash ./brew.sh --dry-run` when `brew.sh` changes.
- For sync-boundary changes, run the relevant `--dry-run` command and inspect the file list before applying.
- For global instruction or shared-skill changes, verify live/tracked parity or run the sync command, then show the exact verification result.
- For Docker image changes, run `docker build` and a basic smoke test (`docker run --rm <image> <version-command>`) to verify the image builds and the primary tool works.

## Common Pitfalls
- Do not treat `.codex/AGENTS.md` as this repo's root agent guide; it is a tracked global-instruction mirror.
- `bootstrap.sh` now syncs skills by default. Use `--delete-skills` for mirror mode; without it, local-only skills are preserved.
- Do not use `brew list --formula` alone to decide what belongs in `Brewfile`; it includes dependencies.
- Do not delete `~/.codex/skills/.system/` or runtime-provided skill directories during skill sync cleanup.
- Keep shell script formatting aligned with CI: 4-space indentation and `shfmt -ci` for the checked scripts.
- `dockerfiles/` is part of the dotfiles repo; edit Dockerfiles directly here.
- The `cross-compile-builder` image platform is hardcoded to `linux/amd64` because the Linaro toolchains are x86_64 binaries. Do not change `IMAGE_PLATFORM`.
- `dockerfiles/` is excluded from `bootstrap.sh` sync; it is not copied to `$HOME`.
- Do not edit `.docker/daemon.json` thinking it is a per-project config; it is the global daemon configuration synced to `~/.docker/` by `bootstrap.sh`.

## Maintenance Trigger
- Update this `AGENTS.md` when the bootstrap boundary, package-management workflow, shared-skill sync model, global-instruction mirror rule, or CI verification commands change.
