# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal Linux dotfiles. No application build, no package manifest. The deliverable is `install.sh`, which symlinks configs into `$HOME` and manages git submodules. Everything else is configuration data.

## Commands

```bash
make check                        # lint + syntax + dry-run + tests — what CI runs
make test                         # bats suite (179 tests)
make lint                         # shellcheck --severity=warning over all scripts
make hooks                        # enable .githooks/pre-commit
make health                       # verify the current installation

bats tests/symlinks.bats               # one file
bats --filter "idempot" tests/*.bats   # by pattern

./install.sh --dry-run --all      # preview; must leave zero filesystem trace
./install.sh --check              # pre-flight dependency check
./install.sh --health-check       # post-install verification (exit status is meaningful)
./install.sh --restore            # roll back to a previous backup
./install.sh --cleanup            # prune old backups, keep newest 5
./install.sh --list-profiles      # named install profiles
./install.sh --show-log           # last run's log
```

Tests live in `tests/*.bats` and run the real installer against a throwaway `$HOME` (`setup_sandbox` in `tests/helpers/common.bash`). Any change to symlink, backup or restore logic needs a test — those paths write into `$HOME`.

**Always `--dry-run` first** when changing install logic — `create_symlink` writes into the real `$HOME`. CI fails the build if a dry-run creates a backup dir or `~/.gitconfig.local`.

To test destructive changes safely, point `$HOME` elsewhere:

```bash
HOME=/tmp/fakehome ASSUME_YES=true NO_COLOR=1 ./install.sh --minimal --dotfiles
```

## Architecture

`install.sh` is a thin entry point: resolve repo root (following symlinks), source `lib/*.sh`, parse args, dispatch. All logic lives in `lib/`, one module per concern:

| Module | Owns |
|---|---|
| `core.sh` | `print_*` output, logging, `confirm`, `is_dry_run`, `is_headless` |
| `profiles.sh` | Named profiles, `profile_skips_config` |
| `location.sh` | Repo relocation, `~/.dotfiles_location` persistence |
| `symlinks.sh` | `create_symlink`, backups, manifest, `--restore` |
| `system.sh` | `detect_system`, `check_dependencies`, `health_check` |
| `packages.sh` | Per-package-manager name lists |
| `dotfiles.sh` | **The symlink map** |
| `suckless.sh` | Submodules and suckless builds |
| `server.sh` | Docker/nginx/firewall/fail2ban |
| `update.sh` | Pull + submodule refresh |
| `ui.sh` | Menu and usage text |

Modules guard against double-sourcing with a `DOTFILES_<NAME>_SOURCED` sentinel — needed because they declare `readonly` values.

Globals (`DOTFILES_DIR`, `BACKUP_DIR`, `DRY_RUN`, `SERVER_MODE`, `MINIMAL_MODE`, `PACKAGE_MANAGER`) are declared in `install.sh` and consumed by the modules. Some carry `# shellcheck disable=SC2034` because their use isn't visible in the declaring file.

### Three invariants

1. **Every filesystem mutation is dry-run guarded.** Start the function with `is_dry_run && { print_dry "..."; return 0; }`. A dry-run that writes anything is a bug CI catches.
2. **GUI work is gated behind `is_headless`** (true for server *or* minimal mode).
3. **Every prompt goes through `confirm`**, which respects `ASSUME_YES` and returns the default when there's no TTY. A prompt that blocks non-interactively is a bug.

Diagnostic commands (`--check`, `--health-check`) set `FINAL_STATUS` so callers can branch on the result. Action commands use `|| true` so a partial failure doesn't abort a longer argument list.

### Symlink layer

`create_symlink src dst` is the only sanctioned way to link. It absolutizes relative sources against `$DOTFILES_DIR`, skips missing sources, is idempotent, backs up conflicts, and validates the result.

The symlink map is the `dotfiles` array in `lib/dotfiles.sh` as `"source:destination"` strings. **Add new configs there** — never call `create_symlink` ad hoc elsewhere.

`BACKUP_DIR` is created lazily by `ensure_backup_dir` only when something is actually displaced. Manifest entries recorded before that point are buffered in `MANIFEST_PENDING` and flushed when the directory appears — so an install that displaces nothing leaves no backup directory, and manifest completeness doesn't depend on the order of the symlink map.

### Profiles

`profiles/*.profile` files are **sourced**, so `load_profile` validates the name against `^[a-zA-Z0-9_-]+$` before touching the path. Profiles preset mode flags; explicit command-line flags are applied afterwards and win.

### Location flexibility

`DOTFILES_DIR` resolves from `BASH_SOURCE`; `~/.dotfiles_location` persists a chosen path but is ignored unless it contains an `install.sh`. Never hardcode an absolute repo path — always `$DOTFILES_DIR`.

### Submodules

Five, all pointing at the owner's own forks: `config/nvim` (init.nvim) and `suckless/{dwm,st,dmenu,dwmblocks}`. Cloning needs `--recursive`. Editing suckless source means committing in the submodule and bumping the pointer here. Each suckless fork keeps a committed `config.h` (personal settings; `config.def.h` stays upstream, some forks need `git add -f`). `suckless/dwmblocks` is dwmblocks-async; its block scripts are `bin/statusbar/sb-*` (see `docs/DESKTOP.md`). `config/nvim` has its own `CLAUDE.md` — read it before touching Neovim config.

### Shell config chain

`.bash_profile` → `.bashrc` → sources `~/.config/shell/{envars,functions,aliases}.sh` in that order. `config/shell/` is symlinked as a directory, so shell changes belong in those three files, not `.bashrc`.

`.gitconfig` is tracked and ends with `[include] path = ~/.gitconfig.local`. Identity and machine-specific settings belong in that untracked local file, which overrides the tracked defaults.

## Bash conventions

`set -euo pipefail` is on everywhere. Two consequences that have already caused real bugs:

- **Use `n=$((n + 1))`, never `((n++))`.** Post-increment from 0 returns exit status 1 and kills the script. This broke every `--location` move before 3.0.0.
- **Declare and assign separately** when capturing output: `local x; x=$(cmd)`. A combined `local x=$(cmd)` masks the exit status.

Other rules:

- Status output only via `print_status` / `print_ok` / `print_warn` / `print_error` / `print_dry` — never bare `echo` for status.
- Don't source files that define common variable names (e.g. `/etc/os-release`) into the current scope; read them in a subshell.
- Generated `/bin/sh` scripts must be POSIX — no `[[ ]]`.
- Section banners use the `# ========================` style.

## Gotchas

- `config/cmus/*` is gitignored except `darkwind.theme` — cmus rewrites its config dir at runtime. Same reasoning for `config/htop/htop_history`.
- `bin/` scripts are symlinked into `~/.local/bin`, so `dirname "$0"` resolves back into the repo. Write runtime state to `$XDG_STATE_HOME/dotfiles`, not next to the script.
- Update `docs/CHANGELOG.md` for user-visible changes and check items off in `docs/TODO.md` when implementing from it.
