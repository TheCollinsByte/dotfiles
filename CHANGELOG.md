# Changelog

All notable changes to this dotfiles project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [2.0.0] - 2025-11-05

### Added
- **Dry-run mode** (`--dry-run`) - Preview all changes without making them
- **Dependency checker** (`--check`) - Verify system requirements before installation
- **Update command** (`--update`) - Easy updates for dotfiles and submodules
- **Symlink validation** - Automatically verify symlinks after creation
- **Distro-specific package lists** - Handle package name differences across distributions
- **Comprehensive comments** - Detailed documentation in install.sh
- **shellcheck** added to default package list
- **Better error handling** - More informative error messages throughout

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
