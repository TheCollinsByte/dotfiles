# Changelog

All notable changes to this dotfiles project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- **dwm desktop foundations** (see `docs/DESKTOP.md`): Super-key keymap,
  gruvbox and FiraCode across dwm/dmenu/st/dunst, statuscmd and restartsig
  patches, dwmblocks-async with ten clickable blocks that hide when
  irrelevant and refresh instantly from hardware keys, dunst notifications,
  an i3lock-color lock screen over the blurred wallpaper with xtrlock
  fallback, auto-lock (dim 9:30, lock 10:00, before suspend), and
  `--wallpapers` for an optional curated set.

### Changed
- **Shell startup is ~8x faster** (~250ms → ~30ms). nvm is lazy-loaded (the
  default node's bin goes on PATH directly, so node, npm and global CLIs work
  immediately), opam runs once instead of twice, and `.bashrc` stops after
  the environment for non-interactive shells.
- **All PATH setup lives in `config/shell/envars.sh`** via an idempotent
  `pathadd`, so entries no longer pile up 3-6 times and `reload` adds
  nothing. Only existing directories are added. `.bash_profile` is now just
  a pointer to `.bashrc`.
- `envars.sh` is POSIX and sourced by `.xinitrc`, so dwmblocks gets PATH and
  the newly exported `TERMINAL=st`.
- **CI**: the real install runs in Debian, Arch and Fedora containers; every
  action is pinned to a commit SHA (kept current by Dependabot); bats is
  pinned; every job has a timeout. `make lint` now also covers the statusbar
  scripts, `.bashrc`, `.bash_profile`, `.xinitrc` and ranger's `scope.sh`.
- `fix-audio.sh` discovers the sound card instead of hardcoding a PCI ID,
  exits quietly where there is none, and no longer forces Master to 100% on
  every login (only the Speaker/Headphone pin amps are raised).
- tmux-continuum is installed (it was configured but missing from the plugin
  list), autosaving every 15 minutes. Run `prefix + I` once to fetch it.

### Fixed
- Neovim config (`config/nvim`): format-on-save, `:ReloadConfig`, snippet
  completion, LSP file-operation renames and the telescope fzf sorter now
  work; mason, telescope and nvim-tree no longer load at every startup;
  textobject jumps stop shadowing `]c` (diff hunks) and `]l` (location
  list); Codeium leaves `<Tab>` to completion (accept with `<C-g>`). Adds a
  headless smoke test (`config/nvim/tests/smoke.lua`).
- Suckless forks brought up to date: dwm 6.8 (fixes a getatomprop() heap
  overflow any X client could trigger), st 0.9.3+ (async-safe sigchld),
  dmenu 5.4+ (three crash fixes). st no longer reads past its colour table
  when drawing the cursor over a selection; dwm's status buffer holds a full
  dwmblocks line.
- Brightness block, idle dim and keys act on the backlight they read; the
  idle dim no longer brightens an already-dim screen.
- `lock` handles a cache path with spaces; music block drops the dash when a
  track has no artist and repairs invalid UTF-8; keyboard rotation keeps
  layout variants; the old `wallpaper.png` copy is excluded from the
  shuffle; the AUR build asks first; `.xinitrc` loads the environment
  before anything else.
- **Relocating into an existing directory nested the repo inside it.**
  `--location` offered to "merge", and `mv` then produced `target/dotfiles`,
  leaving every repointed symlink dangling. Relocation now refuses a target
  that exists and is not an empty directory, and refuses a path inside the
  repo.
- **Relocation repointed unrelated symlinks** whose target merely shared the
  repo path as a string prefix (e.g. `~/dotfiles-old/...`).
- **`--restore` deleted the live file before copying the backup**, so a failed
  copy lost both. Each entry is now copied beside the target and swapped in,
  rolling back if the swap fails.
- **The server firewall could lock out SSH.** ufw allowed the `ssh` service
  (port 22) regardless of where sshd listens, then force-enabled. The rules
  and the fail2ban `sshd` jail now use the ports from `sshd -T` (falling back
  to `sshd_config`), plus the port of the current SSH session.
- Server configuration checks for sudo up front instead of failing midway.
- `alias gh` (history search) shadowed the GitHub CLI; renamed to `hgrep`.
- The `claude`/`ct` aliases are only defined where their wrappers exist.
- **The pre-commit fallback secret check missed keys in large diffs**:
  `grep -q` exiting early made `git diff` die of SIGPIPE, and under
  `pipefail` the 141 read as "no match".
- Statusbar click handlers ran an empty `$TERMINAL`.
- `sb-brightness` crashed on machines without a backlight.
- `.bashrc` no longer forces `TERM=screen-256color`, which broke terminfo in
  st outside tmux.
- `.xinitrc` set the wallpaper before the resolution change finished, and
  ran the VM-only `xrandr --output Virtual-1` on every machine.
- fzf `ctrl-y`/`ctrl-e` used tools that are not installed (`clipcopy`,
  `nvim-qt`); now `xclip` and `nvim`. `ctrl-v` (VS Code) removed.
- On Debian/Ubuntu, `fd` and `bat` install as `fdfind`/`batcat`, so the fzf
  config silently failed; the installer now links the upstream names into
  `~/.local/bin`. apt installs run with `DEBIAN_FRONTEND=noninteractive` so a
  debconf prompt cannot block an unattended run.
- `.gitconfig` set `excludesfile` to a file that does not exist, which also
  disabled git's default global ignore (`~/.config/git/ignore`). Removed.
- `--update` moved submodules to each fork's latest tip (`--remote --merge`)
  instead of the pinned commits, installing untested code and dirtying the
  tree. It now checks out the pinned commits.
- `tcn` dumped files into the Trash root where file managers cannot see or
  restore them; it now uses `gio trash`.
- `sb-iplocate` fetched the public IP over plain HTTP.
- The IntelliJ alias claimed to find the latest version but hardcoded one.
- `egrep` (deprecated, warns on every use) replaced with `grep -E`.
- `.vimrc` errored without opam and hardcoded `/home/collo`.

---

## [3.1.0] - 2026-08-17

### Added
- **Bats test suite** (78 tests) covering symlink creation, idempotency,
  backup/restore round trips, dry-run purity, profiles, relocation, health
  checks and argument parsing. Every test runs the real installer against a
  throwaway `$HOME`. Run with `make test`.
- **Installation profiles** (`--profile work|home|minimal|full`,
  `--list-profiles`) — a profile presets the mode flags, contributes extra
  packages, and skips configs that do not belong on that kind of machine.
  Profile names are validated against a strict pattern, since profile files
  are sourced.
- **Backup cleanup** (`--cleanup`) — deletes old backup directories, keeping
  the newest 5, and reports how much space is reclaimed.
- CI now runs the bats suite on every push.

### Fixed
- **`--health-check` always exited 0**, even when it found broken symlinks, so
  its result could not be branched on. `--check` and `--health-check` now
  propagate their status; action commands still do not.
- **A backup directory was created on every successful install**, even when
  nothing was displaced, because the run manifest was written eagerly.
  Manifest entries are now buffered and flushed only if a real backup happens.
- **Invalid substitution `${#ARRAY[@]:-0}`** in the package builder aborted
  any `--all` run that had a profile loaded.
- `cleanup_backups` computed a size total it never displayed.

### Changed
- `make check` now includes `make test`
- `make lint` additionally covers `profiles/*.profile`, the bats helper and
  the pre-commit hook

---

## [3.0.0] - 2026-08-16

Restructures the installer into modules and adds the safety, CI and
documentation infrastructure the project was missing.

### Added
- **Modular architecture** — `install.sh` is now a thin entry point; all logic
  lives in `lib/` (`core`, `location`, `symlinks`, `system`, `packages`,
  `dotfiles`, `suckless`, `server`, `update`, `ui`)
- **Backup restoration** (`--restore`) — interactive rollback to any previous
  backup, driven by a manifest recorded at install time
- **Health check** (`--health-check`) — verifies symlinks resolve, configs
  parse, required commands exist and submodules are initialized
- **Logging system** — timestamped logs under
  `$XDG_STATE_HOME/dotfiles/logs`, auto-pruned to the last 10, viewable with
  `--show-log`
- **Non-interactive mode** (`--yes` / `ASSUME_YES`) — prompts answer with
  their default when there is no TTY, so the installer never hangs in CI
- **CI pipeline** — shellcheck, syntax, three dry-run modes, a real
  containerized install, an idempotency assertion, secret scanning and
  EditorConfig validation
- **Pre-commit hook** (`.githooks/pre-commit`, enable with `make hooks`) —
  lints staged scripts and blocks committed secrets
- **Makefile** — `make check` runs exactly what CI runs
- **LICENSE** — MIT, which the README had claimed since 1.0.0 without the file
  ever existing
- **CONTRIBUTING.md** — layout, conventions, and how to add a config
- `.editorconfig`, `.shellcheckrc`, `.gitleaks.toml`, `.ecrc`
- `NO_COLOR` support and automatic color suppression when not writing to a TTY
- Support for zypper, apk and xbps distro families
- `config/ranger` is now symlinked — it was tracked but never installed
- Git aliases, `fetch.prune`, `rerere`, `pull.ff=only` and other modern
  defaults in `.gitconfig`

### Fixed
- **Relocation aborted on the first symlink** — `((updated++))` returns a
  non-zero status when incrementing from 0, which killed the script under
  `set -e`. Every `--location` / `--set-location` move was affected.
- **Empty backup directories on every run** — `mkdir -p "$BACKUP_DIR"` ran
  unconditionally in `main()`, littering `$HOME` even on `--help`, `--check`
  and `--dry-run`. Backup directories are now created lazily on first use.
- **`--update` broke on branches with whitespace** — `$(git branch
  --show-current)` was interpolated unquoted into several git commands
- **`--update` failed opaquely with no upstream** — now detected up front with
  the exact `git branch --set-upstream-to` command to fix it
- **`/etc/os-release` clobbered script variables** — it was sourced directly
  into the current scope; now read in a subshell
- **Generated `~/.xinitrc` used `[[ ]]` under a `/bin/sh` shebang** — broken on
  dash and other POSIX shells
- **`~/.gitconfig.local` was dead** — the template was created but
  `.gitconfig` never included it, so machine-specific settings were ignored
- **`fail2ban` jail.local was overwritten** on every server run, discarding an
  operator's tuned configuration
- **`ufw` was enabled before the SSH rule was added**, which can cut off an
  active SSH session
- **Disk-space check could abort the script** when `df` output was
  non-numeric
- **`wallpaper-shuffle.sh`** — wrote its log into the repository, used
  bash-only process substitution under `#!/bin/sh`, could loop forever when
  every image was invalid, and mishandled filenames containing spaces
- Suckless builds now run in subshells, so a failed `cd` cannot leak into the
  next component

### Changed
- Version bumped to 3.0.0 to reflect the restructure
- `--help` and `--version` now work without touching any state
- Mode flags are parsed before commands, so `--all --server` and
  `--server --all` behave identically
- Package installation failures are reported instead of silently continuing
- `.gitignore` expanded to cover editor, install-artifact and OS noise

---

## [2.0.0] - 2025-11-05

### Added
- **Flexible location** (`--location`, `--set-location`) - Choose where to store dotfiles
- **Location persistence** - Remembers your preferred location
- **Auto-migration** - Moves dotfiles and updates all symlinks automatically
- **Server/VPS mode** (`--server`) - Optimized installation for headless servers
- **Minimal mode** (`--minimal`) - Lightweight installation with essential packages only
- **Dry-run mode** (`--dry-run`) - Preview all changes without making them
- **Dependency checker** (`--check`) - Verify system requirements before installation
- **Update command** (`--update`) - Easy updates for dotfiles and submodules
- **Symlink validation** - Automatically verify symlinks after creation
- **Distro-specific package lists** - Handle package name differences across distributions
- **Comprehensive comments** - Detailed documentation in install.sh
- **shellcheck** added to default package list
- **Better error handling** - More informative error messages throughout
- **Auto-detection** - Detects server environments automatically

### Changed
- Replaced `exa` with `eza` (exa is deprecated)
- Improved package installation with distro-specific handling
- Enhanced backup system with better organization
- Updated help text with new commands and examples
- Improved README with new features and examples

### Fixed
- **cpu5 alias bug** - Now correctly sorts by CPU usage (column 3) instead of memory (column 4)
- **eval security issue** - Safer opam environment loading in .bashrc
- **Path issues** - Fixed wallpaper script path in .xinitrc
- **Typo in .tmux.conf** - `contens` → `contents`
- **Function naming** - `print_warning` → `print_warn` consistency
- **Existence checks** - Added checks for cargo and opam before sourcing
- **Quoting issues** - Fixed unquoted variables throughout shell scripts
- **PATH concatenation** - Fixed syntax in .bashrc
- **$PWD vs $DOTFILES_DIR** - Consistent use of DOTFILES_DIR variable
- **Missing dry-run support** - Added to suckless build and submodule setup

### Security
- Safer eval usage for opam environment
- Better validation of user input
- Improved error handling to prevent script failures

---

## [1.0.0] - Initial Release

### Features
- Basic dotfiles installation
- Suckless tools support (dwm, st, dmenu, dwmblocks)
- Git submodule integration
- Interactive TUI menu
- Package installation for multiple distros
- Backup system for existing files
- Shell configuration (bash)
- Vim and Neovim configuration
- Tmux configuration
- X11 configuration

---

## Future Plans

See [TODO.md](TODO.md) for planned enhancements and complete task list.

---

## Documentation

All documentation has been organized in the `docs/` directory for better structure and maintainability.

### Upcoming Features
- Backup restoration system
- Configuration profiles (work, home, minimal)
- Logging system
- Health check command
- Testing framework
- XDG compliance
- Plugin system

---

## Migration Guide

### Upgrading from 1.x to 2.0

1. **Backup your current setup**:
   ```bash
   cp -r ~/.config ~/.config.backup
   ```

2. **Update the repository**:
   ```bash
   cd ~/org/dotfiles
   ./install.sh --update
   ```

3. **Check dependencies**:
   ```bash
   ./install.sh --check
   ```

4. **Preview changes** (optional):
   ```bash
   ./install.sh --dry-run --all
   ```

5. **Apply updates**:
   ```bash
   ./install.sh --dotfiles
   ```

### Breaking Changes

None in this release. All changes are backward compatible.

### Notes

- `exa` has been replaced with `eza`. If you have `exa` installed, you may want to remove it.
- shellcheck is now installed by default. Run `shellcheck install.sh` to validate the script.

---

## Contributing

See [TODO.md](TODO.md) for areas where contributions are welcome.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
