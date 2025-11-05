# Dotfiles TODO & Future Improvements

> **Last Updated**: 2025-11-05  
> **Priority Legend**: 🔥 High | ⭐ Medium | 💡 Low | ✅ Completed

---

## 🚀 High Priority (Do These First)

### Installation & Maintenance
- [ ] 🔥 **Backup Restoration System** (2 hours)
  - Add `--restore` flag to restore from backups
  - List available backups with timestamps
  - Interactive selection of what to restore
  - Verify backup integrity before restoring

- [ ] 🔥 **Logging System** (1 hour)
  - Save installation logs to file
  - Timestamped logs for each run
  - `--show-log` to view last log
  - Auto-cleanup old logs (keep last 10)

- [ ] 🔥 **Health Check Command** (1 hour)
  - `./install.sh --health-check`
  - Verify all symlinks are valid
  - Check config files are parseable
  - Ensure required commands available
  - Check submodules are up to date

- [X] **Dependency Checker** (Completed)
- [X] **Update Command** (Completed)
- [X] **Dry-run Mode** (Completed)

### Documentation
- [ ] 🔥 **Create CONTRIBUTING.md** (30 min)
  - How to add new dotfiles
  - Code style guidelines
  - Testing procedures
  - Pull request process
  - Directory structure explanation

- [ ] 🔥 **Add Troubleshooting Section to README** (30 min)
  - Common issues and solutions
  - How to rollback changes
  - Package installation failures
  - Symlink issues
  - Build failures

- [X] **Add comments to complex sections** (Completed)
- [X] **Create CHANGELOG.md** (Completed)

---

## ⭐ Medium Priority

### Installation Features
- [ ] ⭐ **Configuration Profiles** (3 hours)
  - `./install.sh --profile work|home|minimal|full`
  - Different setups for different machines
  - Profile files in `profiles/` directory
  - Minimal install for servers
  - Full install for workstations

- [ ] ⭐ **Modular Installation** (2 hours)
  - `./install.sh --only shell,vim,tmux`
  - `./install.sh --exclude suckless`
  - Install specific components only
  - Better component organization

- [ ] ⭐ **XDG Base Directory Compliance** (2 hours)
  - Use `$XDG_CONFIG_HOME` instead of hardcoded paths
  - Follow XDG standards
  - Cleaner home directory

- [ ] ⭐ **Testing Framework** (4 hours)
  - Automated tests for dotfiles
  - Verify symlinks are correct
  - Test shell scripts for syntax errors
  - Test on different distros (Docker)

### Package Management
- [ ] ⭐ **AUR Helper Support** (1 hour)
  - Support for yay/paru on Arch
  - Install AUR packages automatically
  - Handle AUR-only packages

- [ ] ⭐ **Custom Package Lists** (1 hour)
  - Allow users to define their own packages
  - `packages.txt` and `packages.optional.txt`
  - User-editable package lists

### Security
- [ ] ⭐ **Secrets Management** (2 hours)
  - Use `.env.example` templates
  - Never commit actual secrets
  - Integrate with password managers
  - Better handling of sensitive data

- [ ] ⭐ **GPG Key Setup** (1 hour)
  - `./install.sh --setup-gpg`
  - Generate GPG key if needed
  - Configure git signing
  - Set up SSH with GPG

---

## 💡 Low Priority (Nice to Have)

### User Experience
- [ ] 💡 **Interactive Setup Wizard** (6 hours)
  - `./install.sh --wizard`
  - Ask user preferences
  - Suggest recommended options
  - Generate custom profile
  - Preview changes before applying

- [ ] 💡 **Progress Indicators** (1 hour)
  - Show spinner for long operations
  - Progress bars for package installation
  - Better visual feedback

- [ ] 💡 **Color Themes** (2 hours)
  - `./install.sh --theme gruvbox|nord|dracula`
  - Theme files in `themes/` directory
  - Apply colors to shell, vim, tmux, terminal
  - Preview themes before applying

- [ ] 💡 **Cleanup Command** (1 hour)
  - `./install.sh --cleanup`
  - Remove old backups (keep last 5)
  - Clean package cache
  - Remove unused submodules

### Advanced Features
- [ ] 💡 **Plugin System** (8 hours)
  - Extensible architecture
  - `plugins/docker/`, `plugins/kubernetes/`
  - `./install.sh --plugin docker`
  - User-contributed plugins

- [ ] 💡 **Hooks System** (2 hours)
  - `pre-install.sh`, `post-install.sh`
  - `pre-backup.sh`, `post-update.sh`
  - Run custom scripts at different stages

- [ ] 💡 **Dotfile Encryption** (3 hours)
  - Use `git-crypt` or `gpg`
  - Encrypt sensitive files
  - Auto-decrypt on install

### Cross-Platform
- [ ] 💡 **Windows Support (WSL)** (4 hours)
  - Detect WSL environment
  - Handle Windows paths
  - Skip X11-specific configs

- [ ] 💡 **macOS Improvements** (2 hours)
  - macOS-specific settings
  - Homebrew bundle file
  - iTerm2 profile

### Automation
- [ ] 💡 **GitHub Actions CI** (3 hours)
  - Automated testing on every commit
  - Run shellcheck automatically
  - Test installation in containers

- [ ] 💡 **Auto-Update Bot** (4 hours)
  - Weekly checks for submodule updates
  - Create PR with updates
  - Test updates before merging

---

## 📦 Software to Install/Configure

### Development Tools
- [ ] **Programming Languages**
  - [ ] Node/nvm (React, Angular, Vue)
  - [ ] Python (pyenv)
  - [X] Rust (rustup) ✅
  - [X] OCaml (opam) ✅
    - Pre-requisites: bubblewrap, rsync, hg, darcs
  - [ ] Zig
  - [ ] Lua Interpreter
  - [ ] GoLang
  - [ ] Java (OpenJDK)
  - [ ] Gradle
  - [ ] Dart/Flutter
  - [X] C/C++ Compilers ✅

- [ ] **IDEs & Editors**
  - [ ] IntelliJ IDEA / Android Studio
  - [ ] VSCode configuration
  - [X] Vim configuration ✅
  - [X] Neovim configuration ✅

### Containerization & Virtualization
- [ ] **Container Tools**
  - [ ] Docker / Docker Compose
  - [ ] Kubernetes (kubectl, minikube)
  - [ ] LXD/LXC
  - [ ] Podman

- [ ] **Virtualization**
  - [ ] KVM (Type A, Native, Bare Metal)
  - [ ] VirtualBox (Type B, Hosted)
  - [ ] QEMU

### Network Tools
- [ ] **Network Diagnostics**
  - [ ] whois
  - [ ] tcpdump
  - [ ] wireshark
  - [ ] iftop
  - [ ] nmap
  - [ ] netcat

### Communication
- [ ] **IRC Client**
  - [ ] weechat configuration
  - [ ] irssi configuration

### System Tools
- [ ] **Utilities**
  - [ ] android-tools (adb)
  - [ ] Android SDK
  - [ ] tree
  - [ ] htop configuration
  - [ ] brillo (brightness control)
    - Up: `brillo -A 40`
    - Down: `brillo -U 40`

### Browsers
- [ ] **Browser Configuration**
  - [ ] Chrome/Chromium
  - [ ] Firefox
  - [ ] Suckless Browser (Surf)
  - [ ] Browser extensions/plugins

---

## 🎨 Configuration & Customization

### Suckless Software
- [X] **DWM** (configured via submodule)
- [X] **st** (configured via submodule)
- [X] **dmenu** (configured via submodule)
- [X] **dwmblocks** (configured via submodule)

### Shell Configuration
- [X] **bash prompt** (configured)
- [X] **bash functions** (configured)
- [ ] **zsh configuration** (optional)
- [ ] **fish configuration** (optional)

### Wallpaper Management
- [X] **Wallpaper Shuffle** (implemented)
- [ ] **Wallpaper Slideshow**
- [ ] **Dynamic wallpaper based on time**

### Fonts
- [ ] **Nerd Fonts Installation**
  - [ ] Font Awesome Icons
  - [ ] Font formats (ttf, otf, Bitmap)
  - [ ] Configure fc-list
  - [ ] Auto-run fc-cache
  - [ ] Paths: `/usr/share/fonts`, `~/.local/share/fonts`

### Color Schemes
- [ ] **Theme Support**
  - [ ] Gruvbox Dark
  - [ ] Monokai Pro
  - [ ] Tomorrow Night
  - [ ] Nord
  - [ ] Dracula

### IntelliJ Plugins
- [ ] **Productivity Plugins**
  - [ ] Sequence Diagram
  - [ ] Material Icon
  - [ ] Protocol Buffer
  - [ ] IdeaVim
  - [ ] Indent Rainbow
  - [ ] Key Promoter X
  - [ ] Mario Progress Bar
  - [ ] Google-Java-Format

---

## 🏗️ Infrastructure

### Distribution Support
- [X] **Arch Linux**
  - [X] pacman support
  - [ ] AUR support (yay/paru)
- [X] **Ubuntu/Debian**
  - [X] apt support
  - [ ] snap support
- [X] **Fedora/RHEL**
  - [X] dnf support
- [X] **macOS**
  - [X] Homebrew support

### Git Submodules
- [X] ✅ **Suckless Software** (dwm, st, dmenu, dwmblocks)
- [X] ✅ **tmux configuration**
- [X] ✅ **Vim configuration**
- [X] ✅ **Neovim configuration**

---

## 📊 Progress Summary

### Completed (v2.0.0)
- ✅ Dry-run mode
- ✅ Dependency checker
- ✅ Update command
- ✅ Symlink validation
- ✅ Distro-specific packages
- ✅ Comprehensive comments
- ✅ ShellCheck compliance
- ✅ Security improvements
- ✅ Better error handling
- ✅ CHANGELOG.md

### In Progress
- 🔄 Documentation improvements
- 🔄 Additional software installation

### Next Up
1. Backup restoration system
2. Logging system
3. Health check command
4. CONTRIBUTING.md
5. Configuration profiles

---

## 🎯 Quick Wins (30 min - 2 hours)

These can be done quickly and provide immediate value:

1. [X] Add shellcheck to packages (Done!)
2. [X] Add --update command (Done!)
3. [X] Add --check command (Done!)
4. [ ] Add logging
5. [ ] Create CONTRIBUTING.md
6. [ ] Add troubleshooting to README
7. [ ] Add cleanup command
8. [ ] Add health check

---

## 📝 Notes

- Keep this file updated as tasks are completed
- Mark items with [X] when done
- Add new items as they come up
- Review quarterly to reprioritize

**Last Review**: 2025-11-05