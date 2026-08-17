# Troubleshooting

Common problems, how to diagnose them, and how to get back to a working state.

---

## Start here

Two commands answer most questions:

```bash
./install.sh --health-check   # what is actually wrong with the installation?
./install.sh --show-log       # what did the last run do?
```

`--health-check` verifies that symlinks resolve, shell configs parse, required
commands exist, and submodules are initialized. It reports errors and warnings
separately: warnings are informational, errors mean something is broken.

---

## Rolling back

### Undo an installation

Every file the installer replaces is moved to
`~/.dotfiles_backup_<timestamp>/`, alongside a `.manifest` recording every
symlink that run created.

```bash
./install.sh --restore
```

You will be shown the available backups, newest first, with a file count and
whether a manifest is present. Selecting one will:

1. Remove the symlinks that run created (so restored files are not written
   through a dangling link), then
2. Move your original files back to their recorded locations.

A backup without a manifest can still be restored, but the symlinks from that
run cannot be identified automatically — you will be warned before
proceeding.

### Undo a single file by hand

```bash
ls ~/.dotfiles_backup_*/                 # find the backup
rm ~/.bashrc                             # remove the symlink
cp ~/.dotfiles_backup_20260816_104053/.bashrc ~/.bashrc
```

### Restore is refusing to run

`--restore` will not proceed without a TTY, so it cannot destroy configs from
a script or pipeline by accident. For automation, opt in explicitly:

```bash
echo 1 | ASSUME_YES=true ./install.sh --restore
```

---

## Installation problems

### "lib/ not found"

The repository is incomplete — usually a partial download or a copied
`install.sh` on its own. Re-clone:

```bash
git clone --recursive https://github.com/TheCollinsByte/dotfiles.git
```

### Package installation fails

Package names differ between distributions and repositories change over time.
Identify the failing package from the log, then either install the rest
manually or skip packages entirely and just link the configs:

```bash
./install.sh --dotfiles     # no package installation at all
```

If your distribution is not detected (`Unsupported system or package
manager`), `--dotfiles` still works — only `--packages` requires a known
package manager.

### Suckless builds fail

Missing build tools or X11 headers:

```bash
# Arch
sudo pacman -S base-devel libx11 libxft libxinerama
# Debian/Ubuntu
sudo apt install build-essential libx11-dev libxft-dev libxinerama-dev
# Fedora
sudo dnf install @development-tools libX11-devel libXft-devel libXinerama-devel
```

`make install` needs root, so the build will prompt for `sudo`. On a headless
machine, skip suckless entirely with `--server` or `--minimal`.

### The installer hangs waiting for input

It is asking a question you cannot see, usually because output is being piped.
Run it non-interactively:

```bash
ASSUME_YES=true ./install.sh --all
```

---

## Symlink problems

### A config is a regular file, not a symlink

`--health-check` reports this as *"exists but is not a symlink (not managed by
dotfiles)"*. The installer never overwrites without backing up, so this means
the file was created after installation, or that path was never installed.
Re-run to take it over (your version is backed up first):

```bash
./install.sh --dotfiles
```

### Broken symlinks after moving the repository

Symlinks point at absolute paths. If you moved the repo manually with `mv`,
the links now dangle. Use the built-in relocation instead, which repoints
every link:

```bash
./install.sh --set-location ~/.dotfiles
```

To repair links after a manual move, point the installer at the new location
and re-run:

```bash
cd /new/path/to/dotfiles && ./install.sh --dotfiles
```

### The installer keeps using the wrong directory

A saved preference at `~/.dotfiles_location` takes priority. Inspect or remove
it:

```bash
cat ~/.dotfiles_location
rm ~/.dotfiles_location
```

Stale preferences pointing at a directory without an `install.sh` are ignored
with a warning.

---

## Shell problems

### "Warning: ~/.config/shell/envars.sh not found"

The `config/shell` directory was not linked. Re-run `./install.sh --dotfiles`,
then confirm:

```bash
ls -la ~/.config/shell
```

### Changes to aliases have no effect

Shell configs are read at startup. Reload:

```bash
source ~/.bashrc     # or: exec bash -l
```

### Git is committing under the wrong name

Identity lives in `~/.gitconfig.local`, which is not tracked and overrides the
repository defaults:

```bash
git config --get user.email     # what git actually resolved
$EDITOR ~/.gitconfig.local
```

---

## Submodule problems

### Submodule directories are empty

They were cloned without `--recursive`:

```bash
git submodule update --init --recursive
```

### Submodule update fails

Refresh the URLs from `.gitmodules` and force a re-sync:

```bash
git submodule sync --recursive
git submodule update --init --recursive --force
```

### `--update` says "no upstream configured"

The branch is not tracking a remote:

```bash
git branch --set-upstream-to=origin/main main
```

### `--update` refuses to pull

Updates use `--ff-only`, so local commits that diverged from upstream will
stop it. Rebase or merge deliberately:

```bash
git pull --rebase origin main
```

---

## Getting help

Open an issue with:

- your distribution and version (`./install.sh --health-check` output helps)
- the exact command you ran
- the relevant log (`./install.sh --show-log`)

Redact anything sensitive before pasting.
