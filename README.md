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
│   ├── shell/          # Shell configurations
├── suckless/           # Suckless programs as git submodules
│   ├── dwm/            # Dynamic Window Manager
│   ├── st/             # Simple Terminal
│   ├── dmenu/          # Dynamic Menu
│   ├── dwmblocks/      # Status bar for DWM
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
git clone --recursive https://github.com/TheCollinsByte/dotfiles.git
cd dotfiles
./install.sh --all
```

### Step-by-Step Installation

1. Clone the repository:
   ```bash
   git clone --recursive https://github.com/TheCollinsByte/dotfiles.git
   cd dotfiles
   ```

2. Run the installation script with your preferred options:
   ```bash
   ./install.sh
   ```

3. Choose options from the interactive menu:
   - Install System Packages
   - Set Up Dotfiles
   - Setup Suckless Repositories
   - Build & Install Suckless Tools
   - Install Everything
   - Show System Info

### Command-line Options

```
Usage: ./install.sh [options]

Options:
  --dry-run, --dry     Preview changes without making them
  -c, --check          Check system dependencies
  -u, --update         Update dotfiles and submodules
  -p, --packages       Install system packages
  -d, --dotfiles       Set up dotfiles
  -r, --suckless-repos Set up Suckless repositories
  -b, --suckless-build Build and install Suckless tools
  -a, --all            Run all setup steps
  -h, --help           Show this help message

Examples:
  ./install.sh --check           Check if system is ready
  ./install.sh --update          Update to latest version
  ./install.sh --dry-run --all   Preview all changes
  ./install.sh --dotfiles        Install dotfiles only
```

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.
