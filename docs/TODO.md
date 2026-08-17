# Dotfiles TODO & Future Improvements

> **Last Updated**: 2026-08-17  
> **Priority Legend**: 🔥 High | ⭐ Medium | 💡 Low | ✅ Completed

---

## 🚀 High Priority (Do These First)

### Installation & Maintenance
- [X] **Backup Restoration System** (Completed in 3.0.0)
  - `--restore` flag, manifest-driven
  - Lists available backups with timestamps and file counts
  - Interactive selection; refuses to run without a TTY
  - Reports backups missing a manifest before proceeding

- [X] **Logging System** (Completed in 3.0.0)
  - Logs under `$XDG_STATE_HOME/dotfiles/logs`
  - Timestamped per run, ANSI stripped
  - `--show-log` views the most recent
  - Auto-pruned to the last 10

- [X] **Health Check Command** (Completed in 3.0.0)
  - `./install.sh --health-check`
  - Validates symlinks resolve and are not dangling
  - Parses shell configs with `bash -n`
  - Checks required commands and submodule initialization

- [X] **Dependency Checker** (Completed)
- [X] **Update Command** (Completed)
- [X] **Dry-run Mode** (Completed)

### Documentation
- [X] **Create CONTRIBUTING.md** (Completed in 3.0.0)
- [X] **Troubleshooting documentation** (Completed in 3.0.0)
  - `docs/TROUBLESHOOTING.md`, linked from the README
  - Rollback, package failures, symlink and submodule problems

- [X] **Add comments to complex sections** (Completed)
- [X] **Create CHANGELOG.md** (Completed)
- [X] **Add LICENSE file** (Completed in 3.0.0 — the README had claimed MIT
      since 1.0.0 without the file existing)

---

## ⭐ Medium Priority

### Installation Features
- [X] **Configuration Profiles** (Completed in 3.1.0)
  - `./install.sh --profile work|home|minimal|full`, plus `--list-profiles`
  - Profile files in `profiles/*.profile`
  - Presets mode flags, adds packages, skips configs per machine type
  - Explicit command-line flags override the profile
  - Profile names validated against traversal (the files are sourced)

- [ ] ⭐ **Modular Installation** (2 hours)
  - `./install.sh --only shell,vim,tmux`
  - `./install.sh --exclude suckless`
  - Install specific components only
  - Better component organization

- [ ] ⭐ **XDG Base Directory Compliance** (2 hours)
  - Use `$XDG_CONFIG_HOME` instead of hardcoded paths
  - Follow XDG standards
  - Cleaner home directory

- [X] **Testing Framework** (Completed in 3.1.0)
  - 78 bats tests in `tests/`, run with `make test`
  - Each test runs the real installer against a throwaway `$HOME`
  - Covers symlinks, idempotency, backup/restore, dry-run purity, profiles,
    relocation, health checks and argument parsing
  - CI runs the suite plus a real containerized install
  - Still open: matrix testing across more distro containers

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

- [X] **Cleanup Command** (Completed in 3.1.0)
  - `./install.sh --cleanup` removes old backups, keeping the newest 5
  - Reports how much space is reclaimed; honors --dry-run
  - Still open: cleaning the package cache and unused submodules

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
- [X] **GitHub Actions CI** (Completed in 3.0.0)
  - Runs on every push and pull request
  - shellcheck, syntax, three dry-run modes
  - Real install in a Debian container, with an idempotency assertion
  - Secret scanning (gitleaks) and EditorConfig validation

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
1. XDG Base Directory compliance
2. AUR helper support (yay/paru)
3. Distro matrix in CI (Arch, Fedora, Alpine containers)
4. Auto-update bot for submodules
5. Custom user-defined package lists

---

## 🎯 Quick Wins (30 min - 2 hours)

These can be done quickly and provide immediate value:

1. [X] Add shellcheck to packages (Done!)
2. [X] Add --update command (Done!)
3. [X] Add --check command (Done!)
4. [X] Add logging (Done in 3.0.0)
5. [X] Create CONTRIBUTING.md (Done in 3.0.0)
6. [X] Add troubleshooting docs (Done in 3.0.0)
7. [X] Add cleanup command (Done in 3.1.0 — `--cleanup`)
8. [X] Add health check (Done in 3.0.0)

---

## 📝 Notes

- Keep this file updated as tasks are completed
- Mark items with [X] when done
- Add new items as they come up
- Review quarterly to reprioritize

**Last Review**: 2025-11-05