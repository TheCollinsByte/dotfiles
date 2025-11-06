#!/usr/bin/env bash

# Dotfiles Installation Script
# ---------------------------
# A modular script to manage dotfiles and system configuration
# Features:
# - Interactive TUI menu
# - Safe symlink handling with backups
# - Package management for multiple distros
# - Suckless tools support

set -euo pipefail

# ========================
# Configuration
# ========================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global paths
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# System info
SYSTEM_TYPE=""
DISTRO=""
PACKAGE_MANAGER=""

# Installation mode flags
DRY_RUN=false
SERVER_MODE=false
MINIMAL_MODE=false
CUSTOM_LOCATION=false

# ========================
# Utility Functions
# ========================

# Print section header
print_section() {
    echo -e "\n${BLUE}==>${NC} ${GREEN}$1${NC}"
}

# Status messages
print_status()  { echo -e "${BLUE}[*]${NC} $1"; }
print_ok()     { echo -e "${GREEN}[✓]${NC} $1"; }
print_warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()  { echo -e "${RED}[✗] ERROR:${NC} $1" >&2; }

# Check if command exists
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Prompt user for dotfiles location
prompt_dotfiles_location() {
    print_section "Dotfiles Location Setup"
    
    local current_location="$DOTFILES_DIR"
    
    echo -e "${BLUE}Current location:${NC} $current_location"
    echo ""
    echo "Common locations:"
    echo "  1) $HOME/.dotfiles         (hidden, popular convention)"
    echo "  2) $HOME/dotfiles          (visible, simple)"
    echo "  3) $HOME/.config/dotfiles  (XDG compliant)"
    echo "  4) $HOME/org/dotfiles      (organized, current default)"
    echo "  5) Custom location"
    echo "  6) Keep current location"
    echo ""
    
    read -rp "Select location (1-6) [6]: " choice
    choice=${choice:-6}
    
    local new_location=""
    
    case $choice in
        1) new_location="$HOME/.dotfiles" ;;
        2) new_location="$HOME/dotfiles" ;;
        3) new_location="$HOME/.config/dotfiles" ;;
        4) new_location="$HOME/org/dotfiles" ;;
        5)
            read -rp "Enter custom path: " new_location
            new_location="${new_location/#\~/$HOME}"  # Expand ~
            ;;
        6)
            print_ok "Keeping current location: $current_location"
            return 0
            ;;
        *)
            print_warn "Invalid choice, keeping current location"
            return 0
            ;;
    esac
    
    # Validate and move if needed
    if [[ -n "$new_location" ]]; then
        new_location=$(realpath -m "$new_location")  # Normalize path
        
        if [[ "$new_location" == "$current_location" ]]; then
            print_ok "Location unchanged: $current_location"
            return 0
        fi
        
        echo ""
        print_status "New location: $new_location"
        
        if [[ -e "$new_location" ]]; then
            print_error "Location already exists: $new_location"
            read -rp "Merge with existing location? (y/N): " merge
            if [[ ! "$merge" =~ ^[Yy]$ ]]; then
                print_warn "Keeping current location"
                return 1
            fi
        fi
        
        read -rp "Move dotfiles to $new_location? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            move_dotfiles "$new_location"
        else
            print_warn "Keeping current location"
        fi
    fi
}

# Move dotfiles to new location
move_dotfiles() {
    local new_location="$1"
    local old_location="$DOTFILES_DIR"
    
    print_status "Moving dotfiles from $old_location to $new_location..."
    
    # Create parent directory
    mkdir -p "$(dirname "$new_location")"
    
    # Move the directory
    if mv "$old_location" "$new_location"; then
        DOTFILES_DIR="$new_location"
        CUSTOM_LOCATION=true
        print_ok "Dotfiles moved to: $new_location"
        
        # Update symlinks to point to new location
        print_status "Updating existing symlinks..."
        update_symlinks_location "$old_location" "$new_location"
        
        # Save location preference
        save_location_preference "$new_location"
    else
        print_error "Failed to move dotfiles"
        return 1
    fi
}

# Update existing symlinks to new location
update_symlinks_location() {
    local old_location="$1"
    local new_location="$2"
    
    # Find all symlinks pointing to old location
    local symlinks=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.vimrc"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
        "$HOME/.xinitrc"
        "$HOME/.Xresources"
        "$HOME/.dmenurc"
    )
    
    local updated=0
    for link in "${symlinks[@]}"; do
        if [[ -L "$link" ]]; then
            local target=$(readlink "$link")
            if [[ "$target" == "$old_location"* ]]; then
                local new_target="${target/$old_location/$new_location}"
                ln -sfn "$new_target" "$link"
                ((updated++))
            fi
        fi
    done
    
    # Update config directory symlinks
    if [[ -d "$HOME/.config" ]]; then
        for link in "$HOME/.config"/*; do
            if [[ -L "$link" ]]; then
                local target=$(readlink "$link")
                if [[ "$target" == "$old_location"* ]]; then
                    local new_target="${target/$old_location/$new_location}"
                    ln -sfn "$new_target" "$link"
                    ((updated++))
                fi
            fi
        done
    fi
    
    if [[ $updated -gt 0 ]]; then
        print_ok "Updated $updated symlink(s)"
    fi
}

# Save location preference for future use
save_location_preference() {
    local location="$1"
    local pref_file="$HOME/.dotfiles_location"
    
    echo "$location" > "$pref_file"
    print_status "Location preference saved to $pref_file"
}

# Load saved location preference
load_location_preference() {
    local pref_file="$HOME/.dotfiles_location"
    
    if [[ -f "$pref_file" ]]; then
        local saved_location=$(cat "$pref_file")
        if [[ -d "$saved_location" ]]; then
            DOTFILES_DIR="$saved_location"
            print_status "Using saved location: $DOTFILES_DIR"
        fi
    fi
}

# Check system dependencies before installation
check_dependencies() {
    print_section "Checking Dependencies"
    
    local all_ok=true
    
    # Check git
    if command_exists git; then
        local git_version=$(git --version | awk '{print $3}')
        print_ok "Git installed (v${git_version})"
    else
        print_error "Git not installed (required)"
        all_ok=false
    fi
    
    # Check disk space (need at least 1GB)
    local available_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $available_space -gt 1 ]]; then
        print_ok "Sufficient disk space (${available_space}GB available)"
    else
        print_warn "Low disk space (${available_space}GB available)"
    fi
    
    # Check network connectivity
    if ping -c 1 github.com >/dev/null 2>&1; then
        print_ok "Network connectivity OK"
    else
        print_warn "Network connectivity issue (may affect submodule updates)"
    fi
    
    # Check for conflicting dotfiles
    local conflicts=()
    for file in .bashrc .vimrc .tmux.conf; do
        if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
            conflicts+=("$HOME/$file")
        fi
    done
    
    if [[ ${#conflicts[@]} -gt 0 ]]; then
        print_warn "Found ${#conflicts[@]} existing config files (will be backed up):"
        for conflict in "${conflicts[@]}"; do
            echo "    - $conflict"
        done
    else
        print_ok "No conflicting files found"
    fi
    
    # Optional tools
    echo ""
    print_status "Optional tools:"
    for tool in shellcheck bat eza fd fzf; do
        if command_exists "$tool"; then
            echo "  ✓ $tool"
        else
            echo "  ✗ $tool (will be installed)"
        fi
    done
    
    if [[ "$all_ok" == false ]]; then
        print_error "Some required dependencies are missing"
        return 1
    fi
    
    print_ok "All required dependencies satisfied"
    return 0
}

# Validate symlink after creation
validate_symlink() {
    local dst="$1"
    local expected_src="$2"
    
    if [[ ! -L "$dst" ]]; then
        print_error "Validation failed: $dst is not a symlink"
        return 1
    fi
    
    local actual_src
    actual_src=$(readlink -f "$dst" 2>/dev/null)
    local expected_full
    expected_full=$(readlink -f "$expected_src" 2>/dev/null)
    
    if [[ "$actual_src" != "$expected_full" ]]; then
        print_error "Validation failed: $dst points to $actual_src instead of $expected_full"
        return 1
    fi
    
    return 0
}

# Create backup of existing file/directory
backup_file() {
    local file="$1"
    if [[ -e "$file" || -L "$file" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_status "[DRY-RUN] Would backup ${file} to ${BACKUP_DIR}"
        else
            print_status "Backing up ${file} to ${BACKUP_DIR}"
            mkdir -p "${BACKUP_DIR}/$(dirname "${file#$HOME/}")"
            mv -v "$file" "${BACKUP_DIR}/${file#$HOME/}" 2>/dev/null || true
        fi
    fi
}

# Create or update symlink
# This function safely creates symlinks with the following features:
# - Converts relative paths to absolute paths
# - Validates source file exists
# - Creates parent directories as needed
# - Backs up existing files/symlinks before replacing
# - Validates symlink after creation
# - Supports dry-run mode
create_symlink() {
    local src="$1"  # Source file/directory to link from
    local dst="$2"  # Destination path where symlink will be created
    
    # Convert to absolute path if not already (handles relative paths)
    [[ $src == /* ]] || src="${DOTFILES_DIR}/${src}"
    
    # Skip if source doesn't exist (prevents broken symlinks)
    if [[ ! -e "$src" ]]; then
        print_warn "Source not found: $src"
        return 1
    fi
    
    # Create parent directory if needed (e.g., ~/.config/nvim for ~/.config/nvim/init.vim)
    mkdir -p "$(dirname "$dst")"
    
    # Handle existing destination (file, directory, or symlink)
    if [[ -e "$dst" || -L "$dst" ]]; then
        # Skip if already linked to the same file (idempotent operation)
        if [[ "$(readlink -f "$dst" 2>/dev/null)" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
            print_status "Symlink already exists: $dst"
            return 0
        fi
        # Backup existing file/directory before replacing
        backup_file "$dst"
    fi
    
    # Create the symlink
    if [[ "$DRY_RUN" == true ]]; then
        print_ok "[DRY-RUN] Would create symlink: $dst → $src"
    else
        if ln -sfn "$src" "$dst"; then
            # Validate the symlink was created correctly
            if validate_symlink "$dst" "$src"; then
                print_ok "Created symlink: $dst → $src"
            else
                print_warn "Symlink created but validation failed: $dst"
                return 1
            fi
        else
            print_error "Failed to create symlink: $dst"
            return 1
        fi
    fi
}

# Recursively create symlinks for directory contents
link_directory() {
    local src_dir="$1"
    local dst_dir="$2"
    
    # Ensure source directory exists
    [[ -d "$src_dir" ]] || { print_error "Source directory not found: $src_dir"; return 1; }
    
    # Create destination directory if it doesn't exist
    mkdir -p "$dst_dir"
    
    # Process each item in the source directory
    while IFS= read -r item; do
        local src="$item"
        local dst="${dst_dir}/${item##*/}"
        
        if [[ -d "$src" ]]; then
            # Recursively handle subdirectories
            link_directory "$src" "$dst"
        else
            # Create symlink for files
            create_symlink "$src" "$dst"
        fi
    done < <(find "$src_dir" -mindepth 1 -maxdepth 1 -not -name '*.md' -not -name 'README*' -not -name '.git*')
}

# ========================
# System Detection
# ========================

detect_system() {
    print_section "Detecting System"
    
    case "$(uname -s)" in
        Linux*)
            SYSTEM_TYPE="Linux"
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                . /etc/os-release
                DISTRO="$ID"
                
                case $ID in
                    arch|manjaro|endeavouros) PACKAGE_MANAGER="pacman" ;;
                    debian|ubuntu|linuxmint|pop|elementary|kali|raspbian) PACKAGE_MANAGER="apt" ;;
                    fedora|rhel|centos|almalinux|rocky) PACKAGE_MANAGER="dnf" ;;
                    opensuse*|suse|sles) PACKAGE_MANAGER="zypper" ;;
                    *) PACKAGE_MANAGER="unknown" ;;
                esac
            fi
            ;;
        Darwin*)
            SYSTEM_TYPE="macOS"
            PACKAGE_MANAGER="brew"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            SYSTEM_TYPE="Windows"
            PACKAGE_MANAGER="choco"
            ;;
        *)
            SYSTEM_TYPE="Unknown"
            PACKAGE_MANAGER="unknown"
            ;;
    esac
    
    # Detect if running on a server (no display server)
    if [[ -z "$DISPLAY" ]] && [[ -z "$WAYLAND_DISPLAY" ]] && [[ ! -d /tmp/.X11-unix ]]; then
        if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
            print_status "No display server detected - appears to be a server environment"
            print_status "Tip: Use --server or --minimal for server-optimized installation"
        fi
    fi
    
    if [[ "$PACKAGE_MANAGER" == "unknown" ]]; then
        print_warn "Unsupported system or package manager detected"
    else
        local mode_info=""
        [[ "$SERVER_MODE" == true ]] && mode_info=" [SERVER MODE]"
        [[ "$MINIMAL_MODE" == true ]] && mode_info=" [MINIMAL MODE]"
        print_ok "Detected: $SYSTEM_TYPE ($DISTRO) with package manager: $PACKAGE_MANAGER${mode_info}"
    fi
}

# ========================
# Package Management
# ========================

install_packages() {
    print_section "Installing Packages"
    
    if [ -z "$PACKAGE_MANAGER" ]; then
        print_warn "Package manager not detected. Skipping package installation."
        return 1
    fi
    
    # Common packages across all distros
    local common_packages=(git curl wget tmux htop vim neovim ripgrep fzf stow shellcheck)
    
    # Server/minimal mode: skip GUI-related packages
    local gui_packages=()
    if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
        gui_packages=(libx11 libxft libxinerama)  # For suckless builds
    else
        print_status "Server/Minimal mode: Skipping GUI packages"
    fi
    
    # Distro-specific package lists (handles naming differences)
    local packages=()
    
    case $PACKAGE_MANAGER in
        pacman)
            # Arch Linux package names
            packages=(
                "${common_packages[@]}"
                fd bat eza
            )
            # Add build tools
            if [[ "$MINIMAL_MODE" == false ]]; then
                packages+=(base-devel)
            fi
            # Add GUI packages if not in server mode
            if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
                packages+=(libx11 libxft libxinerama)
            fi
            ;;
        apt)
            # Debian/Ubuntu package names
            packages=(
                "${common_packages[@]}"
                fd-find bat  # Note: bat might be 'batcat' on older versions
            )
            # Add build tools
            if [[ "$MINIMAL_MODE" == false ]]; then
                packages+=(build-essential)
            fi
            # Add GUI packages if not in server mode
            if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
                packages+=(libx11-dev libxft-dev libxinerama-dev)
            fi
            # Try to install eza from newer repos, fallback gracefully
            if apt-cache search eza 2>/dev/null | grep -q "^eza "; then
                packages+=(eza)
            else
                print_warn "eza not available in repos, skipping"
            fi
            ;;
        dnf)
            # Fedora/RHEL package names
            packages=(
                "${common_packages[@]}"
                fd-find bat eza
            )
            # Add build tools
            if [[ "$MINIMAL_MODE" == false ]]; then
                packages+=(@development-tools)
            fi
            # Add GUI packages if not in server mode
            if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
                packages+=(libX11-devel libXft-devel libXinerama-devel)
            fi
            ;;
        brew)
            # macOS Homebrew package names
            packages=(
                "${common_packages[@]}"
                fd bat eza
            )
            ;;
        *)
            print_warn "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
    
    # Show what will be installed
    print_status "Packages to install: ${packages[*]}"
    
    # Install packages based on package manager
    if [[ "$DRY_RUN" == true ]]; then
        print_status "[DRY-RUN] Would install ${#packages[@]} packages"
        print_status "[DRY-RUN] Using package manager: $PACKAGE_MANAGER"
        return 0
    fi
    
    case $PACKAGE_MANAGER in
        pacman)
            sudo pacman -S --noconfirm --needed "${packages[@]}"
            ;;
        apt)
            sudo apt update
            sudo apt install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        brew)
            brew install "${packages[@]}"
            ;;
    esac
    
    print_ok "Package installation completed"
}

# ========================
# Dotfiles Management
# ========================

setup_dotfiles() {
    print_section "Setting Up Dotfiles"
    
    # Create necessary directories
    local dirs=(
        "$HOME/.config"
        "$HOME/.local/bin"
        "$HOME/.cache/zsh"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    # List of dotfiles to symlink
    # Format: "source:destination"
    local dotfiles=(
        # Core dotfiles (always installed)
        "$DOTFILES_DIR/.bashrc:$HOME/.bashrc"
        "$DOTFILES_DIR/.bash_profile:$HOME/.bash_profile"
        "$DOTFILES_DIR/.vimrc:$HOME/.vimrc"
        "$DOTFILES_DIR/.gitconfig:$HOME/.gitconfig"
        "$DOTFILES_DIR/.tmux.conf:$HOME/.tmux.conf"
        
        # System configuration directories (always installed)
        "$DOTFILES_DIR/config/bat:$HOME/.config/bat"
        "$DOTFILES_DIR/config/htop:$HOME/.config/htop"
        "$DOTFILES_DIR/config/nvim:$HOME/.config/nvim"
        "$DOTFILES_DIR/config/shell:$HOME/.config/shell"
    )
    
    # GUI-related dotfiles (skip in server/minimal mode)
    if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
        dotfiles+=(
            "$DOTFILES_DIR/.xinitrc:$HOME/.xinitrc"
            "$DOTFILES_DIR/.Xresources:$HOME/.Xresources"
            "$DOTFILES_DIR/.dmenurc:$HOME/.dmenurc"
            "$DOTFILES_DIR/config/cmus:$HOME/.config/cmus"
            "$DOTFILES_DIR/config/fontconfig:$HOME/.config/fontconfig"
            "$DOTFILES_DIR/suckless:$HOME/.config/suckless"
        )
    else
        print_status "Server/Minimal mode: Skipping GUI configuration files"
    fi
    
    # Create symlinks for all dotfiles
    # Uses bash parameter expansion to split "source:destination" format
    # ${dotfile%%:*} extracts everything before the first colon (source)
    # ${dotfile#*:} extracts everything after the first colon (destination)
    for dotfile in "${dotfiles[@]}"; do
        local src="${dotfile%%:*}"  # Extract source path
        local dst="${dotfile#*:}"   # Extract destination path
        create_symlink "$src" "$dst"
    done
    
    # Handle special cases
    
    # Link bin scripts to ~/.local/bin
    # This makes custom scripts available in PATH without modifying the bin directory structure
    if [ -d "$DOTFILES_DIR/bin" ]; then
        print_status "Linking bin scripts..."
        mkdir -p "$HOME/.local/bin"
        for script in "$DOTFILES_DIR/bin"/*; do
            # Link both files and directories (e.g., statusbar/)
            if [ -f "$script" ] || [ -d "$script" ]; then
                local script_name
                script_name=$(basename "$script")
                create_symlink "$script" "$HOME/.local/bin/$script_name"
            fi
        done
    fi
    
    # Create .gitconfig.local if it doesn't exist
    if [ ! -f "$HOME/.gitconfig.local" ]; then
        print_status "Creating ~/.gitconfig.local template"
        cat > "$HOME/.gitconfig.local" <<EOF
# Local Git Configuration
# Add your personal git settings here

[user]
	name = Your Name
	email = your.email@example.com

# Add any machine-specific git configuration below
EOF
        print_warn "Please edit ~/.gitconfig.local with your personal information"
    fi
    
    # Install TMUX plugins
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        print_status "Installing TMUX Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
}

# ========================
# Suckless Repositories Setup
# ========================

setup_suckless_repos() {
    print_section "Setting Up Suckless Repositories"
    
    # Git Submodule Management
    # ------------------------
    # This function manages external repositories as git submodules.
    # Submodules allow tracking specific commits of external repos within this dotfiles repo.
    # Benefits: version control, easy updates, clean separation of concerns
    
    # Dry-run mode: show what would be done
    if [[ "$DRY_RUN" == true ]]; then
        print_status "[DRY-RUN] Would initialize and update Git submodules"
        print_status "[DRY-RUN] Would ensure suckless programs (dwm, st, dmenu, dwmblocks) are registered"
        print_status "[DRY-RUN] Would ensure Neovim configuration is registered as submodule"
        return 0
    fi
    
    print_status "Initializing and updating Git submodules..."
    cd "$DOTFILES_DIR" || { print_error "Failed to change to dotfiles directory"; return 1; }
    
    # Initialize and update all submodules defined in .gitmodules
    # --init: Initialize submodules that haven't been initialized yet
    # --recursive: Handle nested submodules (submodules within submodules)
    if git submodule update --init --recursive; then
        print_ok "Git submodules initialized and updated successfully"
    else
        print_error "Failed to initialize and update Git submodules"
        print_status "Attempting to fix submodule issues..."
        
        # Recovery strategy for submodule issues
        # sync: Update submodule URLs from .gitmodules to .git/config
        # --force: Override local changes if necessary
        git submodule sync
        git submodule update --init --recursive --force
    fi
    
    # Ensure all suckless programs are registered as submodules
    # Using parallel arrays to map module names to their repository URLs
    local suckless_modules=("dwm" "st" "dmenu" "dwmblocks")
    local suckless_repos=(
        "https://github.com/TheCollinsByte/dwm"
        "https://github.com/TheCollinsByte/st"
        "https://github.com/TheCollinsByte/dmenu"
        "https://github.com/TheCollinsByte/dwmblocks"
    )
    
    # Loop through indices to access both arrays simultaneously
    # ${!suckless_modules[@]} expands to array indices (0, 1, 2, 3)
    for i in "${!suckless_modules[@]}"; do
        local module="${suckless_modules[$i]}"
        local repo="${suckless_repos[$i]}"
        local module_path="suckless/$module"
        
        # Check if submodule directory exists and contains a .git directory
        # Missing .git means it's not properly initialized as a submodule
        if [[ ! -d "$module_path" || ! -d "$module_path/.git" ]]; then
            print_status "Adding $module as a submodule..."
            # -f flag forces addition even if directory exists
            # || true prevents script exit on error (set -e is active)
            git submodule add -f "$repo" "$module_path" || true
        fi
    done
    
    # Handle Neovim configuration as a submodule
    # Neovim config is kept separate to allow independent version control
    if [[ ! -d "config/nvim/.git" ]]; then
        print_status "Adding Neovim configuration as a submodule..."
        # Save current nvim config if it exists but is not a submodule
        # This prevents data loss if user has existing config
        if [[ -d "config/nvim" ]]; then
            print_status "Backing up existing Neovim configuration..."
            mv "config/nvim" "config/nvim.bak.$(date +%Y%m%d%H%M%S)"
        fi
        
        # Add Neovim config as submodule
        git submodule add -f "https://github.com/TheCollinsByte/init.nvim" "config/nvim"
    fi
    
    print_ok "Suckless repositories and Neovim configuration setup complete"
}

# ========================
# Suckless Tools Setup
# ========================

build_suckless() {
    print_section "Building & Installing Suckless Tools"
    
    # Make sure dependencies are installed
    if ! command -v make >/dev/null 2>&1 || ! command -v gcc >/dev/null 2>&1; then
        print_warn "Build tools (make/gcc) not found. Please install them manually."
        print_status "For Arch: sudo pacman -S base-devel libx11 libxft libxinerama"
        print_status "For Debian/Ubuntu: sudo apt install build-essential libx11-dev libxft-dev libxinerama-dev"
        return 1
    fi
    
    local suckless_dir="$DOTFILES_DIR/suckless"
    if [[ ! -d "$suckless_dir" ]]; then
        print_error "Suckless directory not found. Run the 'Setup Suckless Repositories' option first."
        return 1
    fi
    
    # Build each component
    local components=("dwm" "st" "dmenu" "dwmblocks")
    
    # Dry-run mode: just show what would be built
    if [[ "$DRY_RUN" == true ]]; then
        print_status "[DRY-RUN] Would build and install the following components:"
        for component in "${components[@]}"; do
            local component_dir="$suckless_dir/$component"
            if [[ -d "$component_dir" ]]; then
                print_ok "[DRY-RUN] Would build and install: $component"
            else
                print_warn "[DRY-RUN] Would skip $component: directory not found"
            fi
        done
        return 0
    fi
    
    for component in "${components[@]}"; do
        local component_dir="$suckless_dir/$component"
        
        if [[ ! -d "$component_dir" ]]; then
            print_warn "Skipping $component: directory not found"
            continue
        fi
        
        print_status "Building and installing $component..."
        cd "$component_dir" || { print_error "Failed to change to $component directory"; continue; }
        
        # Clean previous build
        make clean >/dev/null 2>&1
        
        # Build and install
        if make && sudo make install; then
            print_ok "Successfully installed $component"
        else
            print_error "Failed to install $component"
        fi
    done
    
    # Create xinitrc if it doesn't exist
    if [[ ! -f "$HOME/.xinitrc" ]]; then
        print_status "Creating .xinitrc..."
        
        # Create a basic .xinitrc file for running DWM
        cat > "$HOME/.xinitrc" <<EOL
#!/bin/sh

# Load X resources
[[ -f ~/.Xresources ]] && xrdb -merge -I\$HOME ~/.Xresources

# Start compositor if available
if command -v picom >/dev/null 2>&1; then
    picom -b
fi

# Load custom scripts
if [ -d "$HOME/.scripts" ]; then
    for script in "$HOME/.scripts"/*.sh; do
        if [ -x "\$script" ]; then
            \$script &
        fi
    done
fi

# Start status bar
if command -v dwmblocks >/dev/null 2>&1; then
    dwmblocks &
fi

# Start DWM
exec dwm
EOL
        
        # Make it executable
        chmod +x "$HOME/.xinitrc"
        print_ok "Created .xinitrc file"
    else
        print_ok ".xinitrc file already exists"
    fi
    
    print_ok "Suckless tools built and installed successfully"
}

# ========================
# Update System
# ========================

update_dotfiles() {
    print_section "Updating Dotfiles"
    
    cd "$DOTFILES_DIR" || { print_error "Failed to change to dotfiles directory"; return 1; }
    
    # Check if we're in a git repository
    if [[ ! -d ".git" ]]; then
        print_error "Not a git repository. Cannot update."
        return 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        print_warn "You have uncommitted changes:"
        git status --short
        echo ""
        read -rp "Continue with update? (y/N): " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Update cancelled"
            return 0
        fi
    fi
    
    # Fetch latest changes
    print_status "Fetching latest changes..."
    if ! git fetch origin; then
        print_error "Failed to fetch from origin"
        return 1
    fi
    
    # Show what will be updated
    local behind=$(git rev-list --count HEAD..origin/$(git branch --show-current))
    if [[ $behind -eq 0 ]]; then
        print_ok "Already up to date!"
        
        # Still update submodules
        print_status "Checking submodules..."
        if git submodule update --remote --merge; then
            print_ok "Submodules updated"
        fi
        return 0
    fi
    
    print_status "Your branch is $behind commit(s) behind origin"
    echo ""
    print_status "Changes to be applied:"
    git log --oneline HEAD..origin/$(git branch --show-current) | head -10
    echo ""
    
    read -rp "Apply these updates? (y/N): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_status "Update cancelled"
        return 0
    fi
    
    # Pull changes
    print_status "Pulling changes..."
    if git pull origin $(git branch --show-current); then
        print_ok "Successfully updated dotfiles"
    else
        print_error "Failed to pull changes"
        return 1
    fi
    
    # Update submodules
    print_status "Updating submodules..."
    if git submodule update --init --recursive --remote --merge; then
        print_ok "Submodules updated successfully"
    else
        print_warn "Some submodules failed to update"
    fi
    
    print_ok "Update complete!"
    print_status "Run './install.sh --dotfiles' to apply any new configuration changes"
}

# ========================
# Interactive Menu
# ========================

show_menu() {
    clear
    echo -e "${BLUE}╭─────────────────────────────────────────╮"
    echo -e "│          ${BLUE}Dotfiles Installation Menu${NC}     │"
    echo -e "├─────────────────────────────────────────┤"
    echo -e "│                                         │"
    echo -e "│  ${GREEN}1.${NC} Install System Packages             │"
    echo -e "│  ${GREEN}2.${NC} Set Up Dotfiles                     │"
    echo -e "│  ${GREEN}3.${NC} Setup Suckless Repositories         │"
    echo -e "│  ${GREEN}4.${NC} Build & Install Suckless Tools      │"
    echo -e "│  ${BLUE}5.${NC} Install Everything                  │"
    echo -e "│  ${YELLOW}6.${NC} Show System Info                    │"
    echo -e "│  ${RED}0.${NC} Exit                                │"
    echo -e "│                                         │"
    echo -e "╰─────────────────────────────────────────╯${NC}"
    echo -e "\n${YELLOW}Enter your choice (0-6): ${NC}"
}

# ========================
# Main Execution
# ========================

main() {
    # Load saved location preference if exists
    load_location_preference
    
    # Ensure we're in the dotfiles directory
    cd "$DOTFILES_DIR" || { print_error "Failed to change to dotfiles directory"; exit 1; }
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Detect system
    detect_system
    
    # Handle command line arguments
    if [[ $# -gt 0 ]]; then
        while [[ $# -gt 0 ]]; do
            case $1 in
                --dry-run|--dry)
                    DRY_RUN=true
                    print_warn "DRY-RUN MODE: No changes will be made"
                    shift
                    ;;
                --server|-s)
                    SERVER_MODE=true
                    print_status "SERVER MODE: Skipping GUI packages and configurations"
                    shift
                    ;;
                --minimal|-m)
                    MINIMAL_MODE=true
                    print_status "MINIMAL MODE: Installing only essential packages"
                    shift
                    ;;
                --location|-l)
                    prompt_dotfiles_location
                    shift
                    ;;
                --set-location)
                    if [[ -n "${2:-}" ]]; then
                        local new_loc="${2/#\~/$HOME}"
                        new_loc=$(realpath -m "$new_loc")
                        move_dotfiles "$new_loc"
                        shift 2
                    else
                        print_error "--set-location requires a path argument"
                        exit 1
                    fi
                    ;;
                --check|-c) check_dependencies ; shift ;;
                --update|-u) update_dotfiles ; shift ;;
                --packages|-p) install_packages ; shift ;;
                --dotfiles|-d) setup_dotfiles ; shift ;;
                --suckless-repos|-r) 
                    if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
                        setup_suckless_repos
                    else
                        print_warn "Skipping suckless repos in server/minimal mode"
                    fi
                    shift
                    ;;
                --suckless-build|-b)
                    if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
                        build_suckless
                    else
                        print_warn "Skipping suckless build in server/minimal mode"
                    fi
                    shift
                    ;;
                --all|-a)
                    install_packages
                    setup_dotfiles
                    if [[ "$SERVER_MODE" == false ]] && [[ "$MINIMAL_MODE" == false ]]; then
                        setup_suckless_repos
                        build_suckless
                    else
                        print_status "Skipping suckless tools in server/minimal mode"
                    fi
                    shift
                    ;;
                --help|-h) show_usage ; exit 0 ;;
                *) print_error "Unknown option: $1" ; show_usage ; exit 1 ;;
            esac
        done
    else
        # Interactive mode
        while true; do
            show_menu
            read -rp "Select an option (0-6): " choice
            case $choice in
                1) install_packages ; press_any_key ;;
                2) setup_dotfiles ; press_any_key ;;
                3) setup_suckless_repos ; press_any_key ;;
                4) build_suckless ; press_any_key ;;
                5)
                    install_packages
                    setup_dotfiles
                    setup_suckless_repos
                    build_suckless
                    press_any_key
                    ;;
                6) show_system_info ; press_any_key ;;
                0) break ;;
                *) print_warn "Invalid option" ; sleep 1 ;;
            esac
        done
    fi
    
    # Show completion message
    print_ok "Setup completed successfully!"
    if [[ -d "$BACKUP_DIR" && -n "$(ls -A "$BACKUP_DIR")" ]]; then
        print_warn "Backups were created in: $BACKUP_DIR"
    fi
    echo -e "\n${GREEN}Please restart your shell to apply changes.${NC}"
}

# Show usage information
show_usage() {
    echo -e "${BLUE}Usage:${NC} $0 [options]"
    echo -e "\nModes:"
    echo -e "  --dry-run, --dry         Preview changes without making them"
    echo -e "  -s, --server             Server mode (skip GUI packages/configs)"
    echo -e "  -m, --minimal            Minimal mode (essential packages only)"
    echo -e "\nLocation:"
    echo -e "  -l, --location           Choose dotfiles location interactively"
    echo -e "  --set-location <path>    Set dotfiles location directly"
    echo -e "\nCommands:"
    echo -e "  -c, --check              Check system dependencies"
    echo -e "  -u, --update             Update dotfiles and submodules"
    echo -e "  -p, --packages           Install system packages"
    echo -e "  -d, --dotfiles           Set up dotfiles"
    echo -e "  -r, --suckless-repos     Set up Suckless repositories"
    echo -e "  -b, --suckless-build     Build and install Suckless tools"
    echo -e "  -a, --all                Run all setup steps"
    echo -e "  -h, --help               Show this help message"
    echo -e "\nExamples:"
    echo -e "  ${GREEN}# Choose custom location${NC}"
    echo -e "  $0 --location"
    echo -e ""
    echo -e "  ${GREEN}# Set location directly${NC}"
    echo -e "  $0 --set-location ~/.dotfiles"
    echo -e ""
    echo -e "  ${GREEN}# Check if system is ready${NC}"
    echo -e "  $0 --check"
    echo -e ""
    echo -e "  ${GREEN}# Server/VPS installation (no GUI)${NC}"
    echo -e "  $0 --server --all"
    echo -e ""
    echo -e "  ${GREEN}# Minimal installation${NC}"
    echo -e "  $0 --minimal --dotfiles"
    echo -e ""
    echo -e "  ${GREEN}# Preview changes before installing${NC}"
    echo -e "  $0 --dry-run --all"
    echo -e ""
    echo -e "  ${GREEN}# Update existing installation${NC}"
    echo -e "  $0 --update"
}

# Show system information
show_system_info() {
    print_section "System Information"
    echo -e "${BLUE}System:${NC} $(uname -s) $(uname -r)"
    echo -e "${BLUE}Hostname:${NC} $(hostname)"
    echo -e "${BLUE}Shell:${NC} $SHELL"
    echo -e "${BLUE}User:${NC} $USER"
    echo -e "${BLUE}Detected OS:${NC} $SYSTEM_TYPE"
    echo -e "${BLUE}Distribution:${NC} $DISTRO"
    echo -e "${BLUE}Package Manager:${NC} $PACKAGE_MANAGER"
}

# Wait for user to press any key
press_any_key() {
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s -r
}

# Run the main function with all arguments
main "$@"
