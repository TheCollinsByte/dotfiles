<div align="center">

<h1><a href="https://github.com/TheCollinsByte">Dotfiles</a></h1>

<a href="https://github.com/TheCollinsByte/dotfiles/graphs/contributors">
<img alt="People" src="https://img.shields.io/github/contributors/TheCollinsByte/dotfiles?style=flat&color=ffaaf2&label=People"> </a>

<a href="https://github.com/TheCollinsByte/dotfiles/stargazers">
<img alt="Stars" src="https://img.shields.io/github/stars/TheCollinsByte/dotfiles?style=flat&color=98c379&label=Stars"> </a>

<a href="https://github.com/TheCollinsByte/dotfiles/network/members">
<img alt="Forks" src="https://img.shields.io/github/forks/TheCollinsByte/dotfiles?style=flat&color=66a8e0&label=Forks"> </a>

<a href="https://github.com/TheCollinsByte/dotfiles/watchers">
<img alt="Watches" src="https://img.shields.io/github/watchers/TheCollinsByte/dotfiles?style=flat&color=f5d08b&label=Watches"> </a>

<a href="https://github.com/TheCollinsByte/dotfiles/pulse">
<img alt="Last Updated" src="https://img.shields.io/github/last-commit/TheCollinsByte/dotfiles?style=flat&color=e06c75&label="> </a>

</div>

# TheCollinsByte Dotfiles

This repository contains my personal dotfiles and configurations for various Linux tools and applications.

## Repository Structure

```
dotfiles/
├── install.sh          # Entry point: bootstrap, argument parsing, dispatch
├── Makefile            # Developer tasks (make check, make test, ...)
├── tests/              # Bats test suite
├── profiles/           # Named installation profiles
├── lib/                # Installer modules — all logic lives here
│   ├── core.sh         # Output, logging, prompts, shared guards
│   ├── profiles.sh     # Named installation profiles
│   ├── location.sh     # Choosing and relocating the dotfiles directory
│   ├── symlinks.sh     # Backup, symlink creation/validation, restore
│   ├── system.sh       # Platform detection, dependency & health checks
│   ├── packages.sh     # Cross-distro package installation
│   ├── dotfiles.sh     # The symlink map (what lands in $HOME)
│   ├── suckless.sh     # Submodules and suckless builds
│   ├── server.sh       # Server/VPS service configuration
│   ├── update.sh       # Pulling the repo and refreshing submodules
│   └── ui.sh           # Interactive menu and usage text
├── bin/                # Scripts linked into ~/.local/bin
├── config/             # Program configs symlinked into ~/.config
│   ├── bat/            # Bat syntax highlighter config
│   ├── cmus/           # Music player config
│   ├── fontconfig/     # Font configuration
│   ├── htop/           # System monitor config
│   ├── nvim/           # Neovim configuration (git submodule)
│   ├── ranger/         # File manager config
│   └── shell/          # Shell aliases, functions, environment variables
├── docs/               # Documentation
│   ├── CHANGELOG.md            # Version history
│   ├── TODO.md                 # Planned features
│   ├── SERVER_INSTALL.md       # Server/VPS installation guide
│   ├── LOCATION_GUIDE.md       # Location flexibility guide
│   └── TROUBLESHOOTING.md      # Common problems and rollback
├── suckless/           # Suckless programs as git submodules
│   ├── dwm/            # Dynamic Window Manager
│   ├── st/             # Simple Terminal
│   ├── dmenu/          # Dynamic Menu
│   └── dwmblocks/      # Status bar for DWM
├── .githooks/          # Repo-managed git hooks (make hooks)
├── .github/workflows/  # CI pipeline
├── .bashrc             # Bash configuration
├── .bash_profile       # Bash profile
├── .gitconfig          # Git configuration
├── .vimrc              # Vim configuration
├── .xinitrc            # X initialization
├── .tmux.conf          # Tmux configuration
└── README.md           # This file
```

## Features

- **Safe by default** — every change is backed up, validated after creation,
  and reversible with `--restore`
- **Preview anything** — `--dry-run` shows exactly what would happen without
  touching the filesystem
- **Idempotent** — running the installer twice changes nothing the second time
- **Works anywhere** — the repo can live at any path; symlinks follow it
- **Desktop, server and minimal modes** from one script
- **Health checks** — verify an existing installation at any time
- **Logged** — every run is recorded and viewable with `--show-log`
- Multi-distro package handling (pacman, apt, dnf, zypper, apk, brew)
- Git submodule integration for Neovim and the suckless tools
- Linted and tested in CI on every push

## Installation

### Quick Install

```bash
# Clone to any temporary location
git clone --recursive https://github.com/TheCollinsByte/dotfiles.git
cd dotfiles

# Choose your preferred location during installation
./install.sh --location

# Or install directly
./install.sh --all
```

### Custom Location

The script will help you choose the best location for your dotfiles:

```bash
# Option 1: Interactive chooser (Recommended)
./install.sh --location
# Shows menu with popular locations and lets you choose

# Option 2: Set location directly
./install.sh --set-location ~/.dotfiles
# Moves dotfiles to specified location automatically

# Option 3: Clone directly to preferred location
git clone https://github.com/TheCollinsByte/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --all
```

**Popular locations:**
- `~/.dotfiles` - Hidden, popular convention
- `~/dotfiles` - Visible, simple
- `~/.config/dotfiles` - XDG compliant
- `~/org/dotfiles` - Organized
- Or any custom path you prefer!

### Step-by-Step Installation

1. Clone the repository (any location works):
   ```bash
   git clone --recursive https://github.com/TheCollinsByte/dotfiles.git
   cd dotfiles
   ```

2. Choose your preferred location:
   ```bash
   ./install.sh --location
   ```
   
   Or skip this step to use the current location.

3. Install everything:
   ```bash
   ./install.sh --all
   ```

4. Or use the interactive menu:
   - Install System Packages
   - Set Up Dotfiles
   - Setup Suckless Repositories
   - Build & Install Suckless Tools
   - Install Everything
   - Show System Info

### Command-line Options

```
Usage: ./install.sh [options]

Modes (combine with any command):
  --dry-run, --dry       Preview every change without touching the filesystem
  -s, --server           Server mode: skip GUI packages, suckless and X configs
  -m, --minimal          Minimal mode: essential packages only
  -y, --yes              Assume yes for all prompts (non-interactive)
      --profile <name>   Apply a named profile (work, home, minimal, full)
      --list-profiles    List the available profiles

Location:
  -l, --location         Choose the dotfiles location interactively
  --set-location <path>  Move the dotfiles to <path>

Commands:
  -c, --check            Check system dependencies before installing
  -H, --health-check     Verify an existing installation
  -p, --packages         Install system packages
  -d, --dotfiles         Symlink dotfiles into $HOME
  -r, --suckless-repos   Initialize and update git submodules
  -b, --suckless-build   Build and install the suckless tools
      --server-config    Configure server services (docker, nginx, firewall)
  -u, --update           Pull the latest dotfiles and update submodules
      --restore          Restore configs from a previous backup
      --cleanup          Delete old backups, keeping the newest 5
      --show-log         Print the most recent install log
  -a, --all              Run the full installation
  -h, --help             Show this help
  -V, --version          Show the version

Environment:
  NO_COLOR=1             Disable colored output
  ASSUME_YES=true        Same as --yes
```

**Examples**

```bash
./install.sh --check                 # is this machine ready?
./install.sh --dry-run --all         # preview a full install
./install.sh --all                   # full desktop install
./install.sh --server --all          # headless VPS install
./install.sh --minimal --dotfiles    # configs only, nothing else
./install.sh --health-check          # verify an existing install
./install.sh --restore               # roll back to a previous backup
./install.sh --profile work --all    # install using the work profile
./install.sh --cleanup               # prune old backups
```

### Profiles

A profile presets the mode flags, adds extra packages, and skips configs that
do not belong on a given kind of machine — so you do not have to remember
which combination of flags each machine needs.

```bash
./install.sh --list-profiles
./install.sh --profile work --all
```

| Profile | For |
|---|---|
| `full` | Complete desktop workstation (suckless, X, media) |
| `home` | Personal desktop, plus media tooling |
| `work` | Work desktop: dev tooling, no personal media |
| `minimal` | Headless server or container: shell, vim, tmux |

Explicit flags always override a profile, so `--profile full --server` runs in
server mode. Profiles live in `profiles/*.profile`; copy one to add your own.

### Safety and rollback

Every file the installer replaces is moved to a timestamped backup directory
at `~/.dotfiles_backup_<timestamp>/`, together with a manifest of everything
that run created. To undo an installation:

```bash
./install.sh --restore
```

This lists the available backups, removes the symlinks that run created, and
puts your original files back.

Logs for every run are written to
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/logs` (the last 10 are kept) and
can be read with `./install.sh --show-log`.

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) when something goes
wrong.

## Development

```bash
make check     # lint + syntax + dry-run + tests — the same checks CI runs
make test      # bats test suite (156 tests)
make hooks     # enable the pre-commit hook (lint + secret scanning)
make health    # verify the current installation
make help      # list all targets
```

Tests run the real installer against a throwaway `$HOME`, so they never touch
your configuration. Requires [bats](https://github.com/bats-core/bats-core).

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the
repository layout, code style, and how to add a new config.

## Server/VPS Installation

Perfect for Linux VPS servers and headless systems!

### Quick Start for Servers

```bash
# Clone the repository (location doesn't matter)
git clone https://github.com/TheCollinsByte/dotfiles.git
cd dotfiles

# Install in server mode (skips GUI packages)
./install.sh --server --all
```

### What Server Mode Does

**Skips:**
- ❌ X11/GUI packages (libx11, libxft, etc.)
- ❌ Suckless tools (dwm, st, dmenu, dwmblocks)
- ❌ GUI configuration files (.xinitrc, .Xresources, etc.)
- ❌ Font configurations
- ❌ Audio/video tools

**Installs:**
- ✅ Core shell configuration (bash, aliases, functions)
- ✅ Terminal tools (tmux, vim, neovim)
- ✅ CLI utilities (git, curl, wget, htop, ripgrep, fzf, bat, eza)
- ✅ Development tools (shellcheck, stow)

### Minimal Mode

For even lighter installations:

```bash
./install.sh --minimal --dotfiles
```

Minimal mode skips build tools and only installs essential packages.

## Updating

The easiest way to update:

```bash
./install.sh --update
```

This will:
- Check for uncommitted changes
- Show what will be updated
- Pull latest changes
- Update all submodules
- Ask for confirmation before applying

Or manually:

```bash
git pull
git submodule update --init --recursive
```

## Customization

Feel free to modify any configuration files to suit your preferences. The repository structure makes it easy to add or remove components.

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common problems, diagnosis, and rollback
- **[SERVER_INSTALL.md](docs/SERVER_INSTALL.md)** - Complete guide for server/VPS installations
- **[LOCATION_GUIDE.md](docs/LOCATION_GUIDE.md)** - Guide for choosing and managing dotfiles location
- **[CHANGELOG.md](docs/CHANGELOG.md)** - Version history and detailed changes
- **[TODO.md](docs/TODO.md)** - Planned features, improvements, and task list
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Repository layout, code style, and how to add a config

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.
