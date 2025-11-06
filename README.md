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
├── bin/                # Scripts and binaries
├── config/             # Configuration files for various programs
│   ├── bat/            # Bat syntax highlighter config
│   ├── cmus/           # Music player config
│   ├── fontconfig/     # Font configuration
│   ├── htop/           # System monitor config
│   ├── nvim/           # Neovim configuration (git submodule)
│   └── shell/          # Shell configurations
├── docs/               # Documentation
│   ├── CHANGELOG.md    # Version history and changes
│   ├── TODO.md         # Planned features and tasks
│   ├── SERVER_INSTALL.md       # Server/VPS installation guide
│   └── LOCATION_GUIDE.md       # Location flexibility guide
├── suckless/           # Suckless programs as git submodules
│   ├── dwm/            # Dynamic Window Manager
│   ├── st/             # Simple Terminal
│   ├── dmenu/          # Dynamic Menu
│   └── dwmblocks/      # Status bar for DWM
├── .bashrc             # Bash configuration
├── .bash_profile       # Bash profile
├── .gitconfig          # Git configuration
├── .vimrc              # Vim configuration
├── .xinitrc            # X initialization
├── .tmux.conf          # Tmux configuration
├── install.sh          # Installation script
└── README.md           # This file
```

## Features

- Git submodule integration for easier management of external repositories
- Modular configuration for easy customization
- Comprehensive installation script
- Suckless utilities (dwm, st, dmenu, dwmblocks)
- Shell configuration
- Neovim configuration

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

Modes:
  --dry-run, --dry         Preview changes without making them
  -s, --server             Server mode (skip GUI packages/configs)
  -m, --minimal            Minimal mode (essential packages only)

Location:
  -l, --location           Choose dotfiles location interactively
  --set-location <path>    Set dotfiles location directly

Commands:
  -c, --check          Check system dependencies
  -u, --update         Update dotfiles and submodules
  -p, --packages       Install system packages
  -d, --dotfiles       Set up dotfiles
  -r, --suckless-repos Set up Suckless repositories
  -b, --suckless-build Build and install Suckless tools
  -a, --all            Run all setup steps
  -h, --help           Show this help message

Examples:
  # Check if system is ready
  ./install.sh --check
  
  # Server/VPS installation (no GUI)
  ./install.sh --server --all
  
  # Minimal installation
  ./install.sh --minimal --dotfiles
  
  # Preview changes before installing
  ./install.sh --dry-run --all
  
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

- **[CHANGELOG.md](docs/CHANGELOG.md)** - Version history and detailed changes
- **[TODO.md](docs/TODO.md)** - Planned features, improvements, and task list
- **[SERVER_INSTALL.md](docs/SERVER_INSTALL.md)** - Complete guide for server/VPS installations
- **[LOCATION_GUIDE.md](docs/LOCATION_GUIDE.md)** - Guide for choosing and managing dotfiles location

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
