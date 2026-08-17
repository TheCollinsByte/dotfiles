#!/usr/bin/env bash
# lib/system.sh — Platform detection, dependency checks, and health checks.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_SYSTEM_SOURCED:-}" ]] && return 0
readonly DOTFILES_SYSTEM_SOURCED=1

# Map the running platform to SYSTEM_TYPE / DISTRO / PACKAGE_MANAGER.
detect_system() {
    case "$(uname -s)" in
        Linux*)
            SYSTEM_TYPE="Linux"
            if [[ -r /etc/os-release ]]; then
                # Read in a subshell: /etc/os-release defines NAME, VERSION, ID
                # and friends, and sourcing it directly clobbers same-named
                # variables in our own scope.
                DISTRO=$(
                    # shellcheck source=/dev/null
                    . /etc/os-release && echo "${ID:-}"
                )

                case "$DISTRO" in
                    arch|manjaro|endeavouros|artix|garuda)             PACKAGE_MANAGER="pacman" ;;
                    debian|ubuntu|linuxmint|pop|elementary|kali|raspbian|devuan)
                                                                       PACKAGE_MANAGER="apt" ;;
                    fedora|rhel|centos|almalinux|rocky|nobara)         PACKAGE_MANAGER="dnf" ;;
                    opensuse*|suse|sles)                               PACKAGE_MANAGER="zypper" ;;
                    alpine)                                            PACKAGE_MANAGER="apk" ;;
                    void)                                              PACKAGE_MANAGER="xbps" ;;
                    *)                                                 PACKAGE_MANAGER="unknown" ;;
                esac
            fi
            ;;
        Darwin*)
            SYSTEM_TYPE="macOS"
            DISTRO="macos"
            PACKAGE_MANAGER="brew"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            SYSTEM_TYPE="Windows"
            DISTRO="windows"
            PACKAGE_MANAGER="choco"
            ;;
        *)
            SYSTEM_TYPE="Unknown"
            PACKAGE_MANAGER="unknown"
            ;;
    esac

    # Hint at server mode when there is no display server.
    if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" && ! -d /tmp/.X11-unix ]]; then
        if ! is_headless; then
            print_status "No display server detected — this looks like a server environment"
            print_status "Tip: use --server or --minimal for a headless install"
        fi
    fi

    if [[ "$PACKAGE_MANAGER" == "unknown" ]]; then
        print_warn "Unsupported system or package manager"
    else
        local mode_info=""
        [[ "${SERVER_MODE:-false}" == true ]]  && mode_info+=" [SERVER]"
        [[ "${MINIMAL_MODE:-false}" == true ]] && mode_info+=" [MINIMAL]"
        is_dry_run                             && mode_info+=" [DRY-RUN]"
        print_ok "Detected ${SYSTEM_TYPE} (${DISTRO:-unknown}) using ${PACKAGE_MANAGER}${mode_info}"
    fi
}

# Pre-flight check: is this machine ready for an install?
check_dependencies() {
    print_section "Checking Dependencies"

    local all_ok=true

    # --- required ---
    if command_exists git; then
        print_ok "git installed ($(git --version | awk '{print $3}'))"
    else
        print_error "git not installed (required)"
        all_ok=false
    fi

    if [[ "${BASH_VERSINFO[0]:-0}" -ge 4 ]]; then
        print_ok "bash ${BASH_VERSION%%(*} is supported"
    else
        print_error "bash 4.0+ required (found ${BASH_VERSION:-unknown})"
        all_ok=false
    fi

    # --- disk space ---
    # Guard the numeric comparison: df output varies across platforms and a
    # non-numeric value would abort the script under `set -e`.
    local available
    available=$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {print int($4/1048576)}') || available=""
    if [[ "$available" =~ ^[0-9]+$ ]]; then
        if [[ "$available" -ge 1 ]]; then
            print_ok "Sufficient disk space (${available}GB available)"
        else
            print_warn "Low disk space (<1GB available)"
        fi
    else
        print_warn "Could not determine available disk space"
    fi

    # --- network ---
    if command_exists curl && curl -fsS --max-time 5 -o /dev/null https://github.com 2>/dev/null; then
        print_ok "Network connectivity OK"
    elif command_exists ping && ping -c1 -W3 github.com >/dev/null 2>&1; then
        print_ok "Network connectivity OK"
    else
        print_warn "No network connectivity (submodule updates will fail)"
    fi

    # --- conflicts ---
    local -a conflicts=()
    local file
    for file in .bashrc .bash_profile .vimrc .tmux.conf .gitconfig; do
        [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]] && conflicts+=("$HOME/$file")
    done

    if [[ ${#conflicts[@]} -gt 0 ]]; then
        print_warn "${#conflicts[@]} existing config file(s) will be backed up:"
        printf '    - %s\n' "${conflicts[@]}"
    else
        print_ok "No conflicting files found"
    fi

    # --- optional tooling ---
    echo ""
    print_status "Optional tools:"
    local tool
    for tool in shellcheck bat eza fd fzf rg tmux nvim; do
        if command_exists "$tool"; then
            echo -e "  ${GREEN}✓${NC} $tool"
        else
            echo -e "  ${YELLOW}✗${NC} $tool (will be installed)"
        fi
    done

    if [[ "$all_ok" == false ]]; then
        print_error "Some required dependencies are missing"
        return 1
    fi

    print_ok "All required dependencies satisfied"
}

# Post-install verification: is the current installation actually sound?
#
# Unlike --check (which runs before installing), this validates the result:
# symlinks resolve, configs parse, commands exist, submodules are present.
health_check() {
    print_section "Health Check"

    local errors=0 warnings=0

    # --- symlinks ---
    print_status "Verifying symlinks..."
    local -a expected=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.vimrc"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
        "$HOME/.config/shell"
        "$HOME/.config/nvim"
    )

    if ! is_headless; then
        expected+=("$HOME/.xinitrc" "$HOME/.Xresources")
    fi

    local link
    for link in "${expected[@]}"; do
        if [[ ! -e "$link" && ! -L "$link" ]]; then
            print_warn "Missing: $link"
            warnings=$((warnings + 1))
        elif [[ -L "$link" && ! -e "$link" ]]; then
            print_error "Broken symlink: $link → $(readlink "$link")"
            errors=$((errors + 1))
        elif [[ -L "$link" ]]; then
            print_ok "$link"
        else
            print_warn "$link exists but is not a symlink (not managed by dotfiles)"
            warnings=$((warnings + 1))
        fi
    done

    # --- config parseability ---
    echo ""
    print_status "Validating config syntax..."
    local script
    for script in "$DOTFILES_DIR"/config/shell/*.sh "$DOTFILES_DIR"/.bashrc "$DOTFILES_DIR"/.bash_profile; do
        [[ -f "$script" ]] || continue
        if bash -n "$script" 2>/dev/null; then
            print_ok "$(basename "$script") parses cleanly"
        else
            print_error "Syntax error in $script"
            errors=$((errors + 1))
        fi
    done

    if command_exists tmux && [[ -f "$HOME/.tmux.conf" ]]; then
        print_ok ".tmux.conf present"
    fi

    # --- required commands ---
    echo ""
    print_status "Checking required commands..."
    local cmd
    for cmd in git bash; do
        if command_exists "$cmd"; then
            print_ok "$cmd available"
        else
            print_error "$cmd missing"
            errors=$((errors + 1))
        fi
    done

    # --- submodules ---
    echo ""
    print_status "Checking submodules..."
    if [[ -f "$DOTFILES_DIR/.gitmodules" ]] && command_exists git; then
        local path
        while IFS= read -r path; do
            [[ -n "$path" ]] || continue
            if [[ -e "$DOTFILES_DIR/$path/.git" ]]; then
                print_ok "$path initialized"
            else
                print_warn "$path not initialized (run: git submodule update --init --recursive)"
                warnings=$((warnings + 1))
            fi
        done < <(git -C "$DOTFILES_DIR" config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
    else
        print_warn "No .gitmodules found"
        warnings=$((warnings + 1))
    fi

    # --- summary ---
    echo ""
    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        print_ok "Health check passed — installation looks good"
        return 0
    fi

    print_status "Health check finished: ${errors} error(s), ${warnings} warning(s)"
    [[ $errors -gt 0 ]] && return 1
    return 0
}

show_system_info() {
    print_section "System Information"
    echo -e "${BLUE}System:${NC}          $(uname -s) $(uname -r)"
    echo -e "${BLUE}Hostname:${NC}        $(hostname 2>/dev/null || echo unknown)"
    echo -e "${BLUE}Shell:${NC}           ${SHELL:-unknown}"
    echo -e "${BLUE}User:${NC}            ${USER:-unknown}"
    echo -e "${BLUE}Detected OS:${NC}     ${SYSTEM_TYPE:-unknown}"
    echo -e "${BLUE}Distribution:${NC}    ${DISTRO:-unknown}"
    echo -e "${BLUE}Package Manager:${NC} ${PACKAGE_MANAGER:-unknown}"
    echo -e "${BLUE}Dotfiles Dir:${NC}    ${DOTFILES_DIR}"
    echo -e "${BLUE}Log Dir:${NC}         ${LOG_DIR}"
}
