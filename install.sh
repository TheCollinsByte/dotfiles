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
readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# System info
SYSTEM_TYPE=""
DISTRO=""
PACKAGE_MANAGER=""

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

# Create backup of existing file/directory
backup_file() {
    local file="$1"
    if [[ -e "$file" || -L "$file" ]]; then
        print_status "Backing up ${file} to ${BACKUP_DIR}"
        mkdir -p "${BACKUP_DIR}/$(dirname "${file#$HOME/}")"
        mv -v "$file" "${BACKUP_DIR}/${file#$HOME/}" 2>/dev/null || true
    fi
}

# Create or update symlink
create_symlink() {
    local src="$1"
    local dst="$2"
    
    # Convert to absolute path if not already
    [[ $src == /* ]] || src="${DOTFILES_DIR}/${src}"
    
    # Skip if source doesn't exist
    if [[ ! -e "$src" ]]; then
        print_warn "Source not found: $src"
        return 1
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"
    
    # Handle existing destination
    if [[ -e "$dst" || -L "$dst" ]]; then
        # Skip if already linked to the same file
        if [[ "$(readlink -f "$dst" 2>/dev/null)" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
            print_status "Symlink already exists: $dst"
            return 0
        fi
        backup_file "$dst"
    fi
    
    # Create the symlink
    if ln -sfn "$src" "$dst"; then
        print_ok "Created symlink: $dst → $src"
    else
        print_error "Failed to create symlink: $dst"
        return 1
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
    
    if [[ "$PACKAGE_MANAGER" == "unknown" ]]; then
        print_warn "Unsupported system or package manager detected"
    else
        print_ok "Detected: $SYSTEM_TYPE ($DISTRO) with package manager: $PACKAGE_MANAGER"
    fi
}

# ========================
# Package Management
# ========================

install_packages() {
    print_section "Installing Packages"
    
    if [ -z "$PACKAGE_MANAGER" ]; then
        print_warning "Package manager not detected. Skipping package installation."
        return 1
    fi
    
    # Base packages that are common across most systems
    local base_packages=(
        git curl wget tmux htop vim neovim ripgrep fd-find
        fzf bat exa stow
    )
    
    # Install packages based on package manager
    case $PACKAGE_MANAGER in
        pacman)
            sudo pacman -S --noconfirm --needed "${base_packages[@]}"
            ;;
        apt)
            sudo apt update
            sudo apt install -y "${base_packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${base_packages[@]}"
            ;;
        brew)
            brew install "${base_packages[@]}"
            ;;
        *)
            print_warning "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
    
    # Additional tools that might need special handling
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
        # Home directory dotfiles
        "$PWD/.bashrc:$HOME/.bashrc"
        "$PWD/.bash_profile:$HOME/.bash_profile"
        "$PWD/.vimrc:$HOME/.vimrc"
        "$PWD/.gitconfig:$HOME/.gitconfig"
        "$PWD/.tmux.conf:$HOME/.tmux.conf"
        "$PWD/.xinitrc:$HOME/.xinitrc"
        "$PWD/.Xresources:$HOME/.Xresources"
        "$PWD/.dmenurc:$HOME/.dmenurc"

        # System configuration directories
        "$PWD/config/cmus:$HOME/.config/cmus"
        "$PWD/config/fontconfig:$HOME/.config/fontconfig"
        "$PWD/config/bat:$HOME/.config/bat"
        "$PWD/config/htop:$HOME/.config/htop"
        "$PWD/config/nvim:$HOME/.config/nvim"
        "$PWD/config/shell:$HOME/.config/shell"
        "$PWD/suckless:$HOME/.config/suckless"
    )
    
    # Create symlinks
    for dotfile in "${dotfiles[@]}"; do
        local src="${dotfile%%:*}"
        local dst="${dotfile#*:}"
        create_symlink "$src" "$dst"
    done
    
    # Handle special cases
    if [ ! -f "$HOME/.gitconfig.local" ]; then
        print_status "Creating ~/.gitconfig.local"
        cp "$DOTFILES_DIR/config/git/.gitconfig.local.example" "$HOME/.gitconfig.local"
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
    
    # Initialize/update submodules for suckless programs
    print_status "Initializing and updating Git submodules..."
    cd "$DOTFILES_DIR" || { print_error "Failed to change to dotfiles directory"; return 1; }
    
    # Initialize and update all submodules
    if git submodule update --init --recursive; then
        print_ok "Git submodules initialized and updated successfully"
    else
        print_error "Failed to initialize and update Git submodules"
        print_status "Attempting to fix submodule issues..."
        
        # Try to fix submodule issues
        git submodule sync
        git submodule update --init --recursive --force
    fi
    
    # Check for each suckless submodule
    local suckless_modules=("dwm" "st" "dmenu" "dwmblocks")
    local suckless_repos=(
        "https://github.com/TheCollinsByte/dwm"
        "https://github.com/TheCollinsByte/st"
        "https://github.com/TheCollinsByte/dmenu"
        "https://github.com/TheCollinsByte/dwmblocks"
    )
    
    for i in "${!suckless_modules[@]}"; do
        local module="${suckless_modules[$i]}"
        local repo="${suckless_repos[$i]}"
        local module_path="suckless/$module"
        
        if [[ ! -d "$module_path" || ! -d "$module_path/.git" ]]; then
            print_status "Adding $module as a submodule..."
            git submodule add -f "$repo" "$module_path"
        fi
    done
    
    # Handle Neovim configuration as a submodule
    if [[ ! -d "config/nvim/.git" ]]; then
        print_status "Adding Neovim configuration as a submodule..."
        # Save current nvim config if it exists but is not a submodule
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
        print_status "Installing build dependencies..."
        install_packages "make gcc libx11-dev libxft-dev libxinerama-dev"
    fi
    
    local suckless_dir="$DOTFILES_DIR/suckless"
    if [[ ! -d "$suckless_dir" ]]; then
        print_error "Suckless directory not found. Run the 'Setup Suckless Repositories' option first."
        return 1
    fi
    
    # Build each component
    local components=("dwm" "st" "dmenu" "dwmblocks")
    
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
                --packages|-p) install_packages ; shift ;;
                --dotfiles|-d) setup_dotfiles ; shift ;;
                --suckless-repos|-r) setup_suckless_repos ; shift ;;
                --suckless-build|-b) build_suckless ; shift ;;
                --all|-a)
                    install_packages
                    setup_dotfiles
                    setup_suckless_repos
                    build_suckless
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
    echo -e "\nOptions:"
    echo -e "  -p, --packages       Install system packages"
    echo -e "  -d, --dotfiles       Set up dotfiles"
    echo -e "  -r, --suckless-repos Set up Suckless repositories"
    echo -e "  -b, --suckless-build Build and install Suckless tools"
    echo -e "  -a, --all            Run all setup steps"
    echo -e "  -h, --help           Show this help message"
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
