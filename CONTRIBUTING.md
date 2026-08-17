# Contributing

Thanks for taking an interest. This repo is a personal dotfiles setup, but it
is structured so that changes stay reviewable and safe to run on someone
else's machine.

## Getting set up

```bash
git clone --recursive https://github.com/TheCollinsByte/dotfiles.git
cd dotfiles
make hooks     # enable the pre-commit hook
make check     # lint + syntax + dry-run, the same checks CI runs
```

Required tooling: `shellcheck` (for `make lint`) and
[`bats`](https://github.com/bats-core/bats-core) (for `make test`).
Optional: `shfmt` (`make fmt`), `gitleaks` (`make secrets`).

```bash
# bats, if your package manager does not have it
git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats
sudo /tmp/bats/install.sh /usr/local
```

## The golden rule

**Never test destructive changes by running the installer directly.** Use
dry-run first:

```bash
./install.sh --dry-run --all
```

`install.sh` writes into `$HOME`. Any code path that mutates the filesystem
without an `is_dry_run` guard is a bug, and CI fails the build if a dry-run
leaves a trace.

## Repository layout

```
install.sh          Thin entry point: bootstrap, argument parsing, dispatch
lib/                One module per concern — all real logic lives here
  core.sh           Output, logging, prompts, shared guards
  profiles.sh       Named installation profiles
  location.sh       Choosing and relocating the dotfiles directory
  symlinks.sh       Backup, symlink creation/validation, restore
  system.sh         Platform detection, dependency checks, health check
  packages.sh       Cross-distro package installation
  dotfiles.sh       The symlink map ($HOME configuration)
  suckless.sh       Submodules and suckless builds
  server.sh         Server/VPS service configuration
  update.sh         Pulling the repo and refreshing submodules
  ui.sh             Interactive menu and usage text
bin/                Scripts linked into ~/.local/bin
config/             Program configs symlinked into ~/.config
profiles/           Named installation profiles (*.profile)
tests/              Bats test suite
  helpers/common.bash   Sandbox setup and assertions
docs/               Extended documentation
.githooks/          Repo-managed git hooks
```

## Adding a new config

1. Put the file under `config/<program>/` (or at the repo root for a classic
   `~/.foorc` dotfile).
2. Add one line to the `dotfiles` array in `lib/dotfiles.sh`:

   ```bash
   "$DOTFILES_DIR/config/foo:$HOME/.config/foo"
   ```

   Do not call `create_symlink` anywhere else — the array is the single source
   of truth for what gets installed.
3. If it is a GUI program, add it to the `is_headless` branch so server
   installs skip it. If it should be absent on some machine types, add its
   basename to that profile's `PROFILE_SKIP_CONFIGS`.
4. If the program rewrites its own config at runtime, add the generated files
   to `.gitignore` (see the cmus and htop entries for the pattern).
5. Verify: `./install.sh --dry-run --dotfiles`, then add a test asserting the
   symlink is created.

## Adding a profile

Copy an existing file in `profiles/`. A profile may set `PROFILE_DESCRIPTION`,
`PROFILE_SERVER_MODE`, `PROFILE_MINIMAL_MODE`, `PROFILE_EXTRA_PACKAGES` and
`PROFILE_SKIP_CONFIGS` (matched against the destination's basename).

Profile files are **sourced**, so they execute. Keep them declarative —
assignments only, no logic — and never read untrusted profile files. The name
is validated against `^[a-zA-Z0-9_-]+$` before loading, which is what stops a
`--profile ../../something` from escaping the directory.

## Code style

Enforced by `.editorconfig` and `.shellcheckrc`; run `make check` before
pushing.

- `#!/usr/bin/env bash` and `set -euo pipefail` at the top of every script.
- 4-space indentation, LF endings, final newline.
- Status output goes through `print_status` / `print_ok` / `print_warn` /
  `print_error` / `print_dry` — never a bare `echo`.
- Quote every expansion. Prefer `[[ ]]` over `[ ]` in bash.
- Use `count=$((count + 1))`, **not** `((count++))`. Under `set -e`, a
  post-increment from zero returns a non-zero status and kills the script.
- Declare and assign separately when capturing command output:
  `local x; x=$(cmd)` — a combined `local x=$(cmd)` masks the exit status.
- Every function that touches the filesystem must start with an
  `is_dry_run` guard that prints via `print_dry` and returns.
- Comment the *why*, not the *what*. Explain non-obvious guards and
  workarounds; skip narrating what the code plainly says.

## Modes

Three flags gate behavior and must be honored by any new code:

| Flag | Variable | Meaning |
|---|---|---|
| `--dry-run` | `DRY_RUN` | Print intentions, change nothing |
| `--server` | `SERVER_MODE` | Headless: no X11, no suckless, no GUI configs |
| `--minimal` | `MINIMAL_MODE` | Essential packages only, no build tools |

Use the helpers rather than testing the variables directly: `is_dry_run` and
`is_headless` (true for server *or* minimal).

Anything interactive must go through `confirm`, which respects `ASSUME_YES`
and answers with the default when there is no TTY. A prompt that blocks a
non-interactive run is a bug.

## Testing a change

```bash
make check                        # what CI runs: lint, syntax, dry-run, tests
make test                         # bats suite only
bats tests/symlinks.bats          # a single file
bats --filter "idempot" tests/*.bats   # tests matching a pattern
```

### Writing tests

Tests live in `tests/*.bats` and use the helper in `tests/helpers/common.bash`.
Every test gets a throwaway `$HOME` via `setup_sandbox`, so the suite never
touches your real configuration:

```bash
load helpers/common

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "a new config gets linked" {
    run_install --minimal --dotfiles
    assert_success
    assert_symlink "$TEST_HOME/.config/foo"
}
```

Available assertions: `assert_success`, `assert_failure`,
`assert_output_contains`, `assert_output_not_contains`, `assert_symlink`,
`assert_not_exists`, `assert_file_contains`, and `count_backups`.

Any change to symlink, backup or restore logic needs a test. Those paths write
into `$HOME`, and a regression there costs a user their configuration.

For a full end-to-end check against a clean system:

```bash
docker run --rm -v "$PWD:/src:ro" -e ASSUME_YES=true debian:stable-slim bash -c \
  'apt-get update -qq && apt-get install -y -qq git && cp -r /src /w && cd /w && ./install.sh --minimal --dotfiles'
```

## Submodules

`config/nvim` and `suckless/*` are submodules pointing at separate repos.
Changes to their contents belong in those repos; this repo only tracks which
commit to use.

```bash
git -C suckless/dwm checkout -b my-change
# ... edit, commit, push in the submodule ...
git add suckless/dwm    # record the new pointer here
```

## Commits and pull requests

- Present tense, imperative subject: `Add ranger config to symlink map`.
- One logical change per commit. Keep unrelated formatting out of the diff.
- PRs should say what you changed, why, and how you verified it — including
  which distro you tested on, since package names differ per manager.
- CI must be green. If a check is wrong, fix the check in the same PR rather
  than working around it.

## Reporting problems

Open an issue with your distro and version, the exact command you ran, and the
relevant install log (`./install.sh --show-log`). Redact anything sensitive
before pasting.
