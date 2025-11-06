# Server/VPS Installation Guide

Quick reference for installing dotfiles on Linux VPS servers and headless systems.

---

## 🚀 Quick Start

### One-Line Installation

```bash
git clone https://github.com/TheCollinsByte/dotfiles.git && cd dotfiles && ./install.sh --server --all
```

### Step-by-Step

```bash
# 1. Clone the repository (location doesn't matter)
git clone https://github.com/TheCollinsByte/dotfiles.git
cd dotfiles

# 2. (Optional) Choose your preferred location
./install.sh --location

# 3. Check system compatibility
./install.sh --check

# 4. Preview what will be installed
./install.sh --server --dry-run --all

# 5. Install everything
./install.sh --server --all
```

**Note:** The script will automatically move dotfiles to your preferred location if you use `--location`. You don't need to specify the location when cloning.

---

## 📦 What Gets Installed

### Server Mode (`--server`)

**Packages Installed:**
- ✅ git, curl, wget
- ✅ tmux (terminal multiplexer)
- ✅ vim, neovim (editors)
- ✅ htop (system monitor)
- ✅ ripgrep, fzf (search tools)
- ✅ bat, eza (modern cat/ls replacements)
- ✅ stow (symlink manager)
- ✅ shellcheck (shell script linter)

**Configuration Files:**
- ✅ `.bashrc`, `.bash_profile`
- ✅ `.vimrc`
- ✅ `.gitconfig`
- ✅ `.tmux.conf`
- ✅ `~/.config/nvim/` (Neovim config)
- ✅ `~/.config/shell/` (aliases, functions, env vars)
- ✅ `~/.config/bat/` (bat config)
- ✅ `~/.config/htop/` (htop config)
- ✅ `~/.local/bin/` (custom scripts)

**Skipped (GUI-related):**
- ❌ X11/Wayland packages
- ❌ Suckless tools (dwm, st, dmenu)
- ❌ `.xinitrc`, `.Xresources`
- ❌ Font configurations
- ❌ Audio/video tools

---

## 🎯 Installation Modes

### Server Mode
```bash
./install.sh --server --all
```
- Skips all GUI packages and configurations
- Perfect for VPS, cloud servers, headless systems
- Installs development tools

### Minimal Mode
```bash
./install.sh --minimal --dotfiles
```
- Even lighter than server mode
- Skips build tools (gcc, make, etc.)
- Only essential packages
- Perfect for containers or resource-constrained systems

### Dry-Run Mode
```bash
./install.sh --server --dry-run --all
```
- Preview all changes before applying
- No files modified
- No packages installed
- Safe to run anytime

---

## 🔧 Common Tasks

### Install Only Dotfiles (No Packages)
```bash
./install.sh --server --dotfiles
```

### Install Only Packages
```bash
./install.sh --server --packages
```

### Update Existing Installation
```bash
./install.sh --update
```

### Check System Dependencies
```bash
./install.sh --check
```

---

## 📋 Supported Distributions

### Debian/Ubuntu
```bash
# Automatic detection
./install.sh --server --all

# Uses apt package manager
# Installs: build-essential, fd-find, bat, etc.
```

### RHEL/CentOS/Fedora
```bash
# Automatic detection
./install.sh --server --all

# Uses dnf package manager
# Installs: @development-tools, fd-find, bat, eza
```

### Arch Linux
```bash
# Automatic detection
./install.sh --server --all

# Uses pacman package manager
# Installs: base-devel, fd, bat, eza
```

---

## 🛠️ Post-Installation

### Reload Shell Configuration
```bash
source ~/.bashrc
```

### Verify Installation
```bash
# Check if tools are available
which tmux vim nvim git fzf bat eza

# Test aliases
alias

# Test functions
type ex cl
```

### Configure Git
```bash
# Edit your personal git config
vim ~/.gitconfig.local

# Add your details:
[user]
    name = Your Name
    email = your.email@example.com
```

---

## 🔄 Updating

### Update Dotfiles
```bash
cd ~/org/dotfiles
./install.sh --update
```

This will:
1. Check for uncommitted changes
2. Show what will be updated
3. Pull latest changes
4. Update all submodules
5. Ask for confirmation

### Manual Update
```bash
cd ~/org/dotfiles
git pull
git submodule update --init --recursive
./install.sh --server --dotfiles
```

---

## 🐛 Troubleshooting

### Package Installation Fails
```bash
# Update package manager first
sudo apt update          # Debian/Ubuntu
sudo dnf update          # Fedora/RHEL
sudo pacman -Syu         # Arch

# Then retry
./install.sh --server --packages
```

### Symlink Conflicts
```bash
# Backup existing configs
mv ~/.bashrc ~/.bashrc.backup
mv ~/.vimrc ~/.vimrc.backup

# Then retry
./install.sh --server --dotfiles
```

### Network Issues
```bash
# Check connectivity
ping github.com

# If behind proxy, configure git
git config --global http.proxy http://proxy:port
```

### Permission Issues
```bash
# Ensure you own the dotfiles directory
sudo chown -R $USER:$USER ~/org/dotfiles

# Make install script executable
chmod +x ~/org/dotfiles/install.sh
```

---

## 💡 Tips for Servers

### 1. Use tmux for Persistent Sessions
```bash
# Start tmux
tmux

# Detach: Ctrl+b, then d
# Reattach: tmux attach
```

### 2. Customize for Your Server
```bash
# Edit server-specific settings
vim ~/.gitconfig.local
vim ~/.config/shell/aliases.sh
```

### 3. Keep It Updated
```bash
# Add to crontab for weekly updates
0 0 * * 0 cd ~/org/dotfiles && git pull
```

### 4. Minimal Footprint
```bash
# For containers or minimal systems
./install.sh --minimal --dotfiles

# Skip even more
./install.sh --server --dotfiles
```

---

## 📊 Comparison

| Feature | Desktop | Server | Minimal |
|---------|---------|--------|---------|
| Shell config | ✅ | ✅ | ✅ |
| Vim/Neovim | ✅ | ✅ | ✅ |
| Tmux | ✅ | ✅ | ✅ |
| CLI tools | ✅ | ✅ | ✅ |
| Build tools | ✅ | ✅ | ❌ |
| GUI packages | ✅ | ❌ | ❌ |
| Suckless tools | ✅ | ❌ | ❌ |
| X11 configs | ✅ | ❌ | ❌ |

---

## 🔗 Resources

- [Main README](README.md) - Full documentation
- [CHANGELOG](CHANGELOG.md) - Version history
- [TODO](TODO.md) - Planned features
- [GitHub Issues](https://github.com/TheCollinsByte/dotfiles/issues) - Report bugs

---

## 📝 Examples

### Fresh Ubuntu VPS
```bash
# Install git first
sudo apt update && sudo apt install -y git

# Clone and install (location doesn't matter)
git clone https://github.com/TheCollinsByte/dotfiles.git
cd dotfiles
./install.sh --server --all
source ~/.bashrc
```

### With Custom Location
```bash
# Clone anywhere
git clone https://github.com/TheCollinsByte/dotfiles.git
cd dotfiles

# Choose location during installation
./install.sh --location
# Then select your preferred location from the menu

# Install in server mode
./install.sh --server --all
source ~/.bashrc
```

### Existing Server (Update)
```bash
# The script remembers your location
./install.sh --update
source ~/.bashrc
```

### Docker Container
```bash
# In Dockerfile
RUN git clone https://github.com/TheCollinsByte/dotfiles.git /tmp/dotfiles && \
    cd /tmp/dotfiles && \
    ./install.sh --set-location /root/.dotfiles && \
    ./install.sh --minimal --dotfiles
```

---

**Happy server configuration! 🎉**
