#!/usr/bin/env bash
# lib/packages.sh — Cross-distro package installation.
#
# Package names differ per distro, so each manager gets its own name list
# built from a shared logical set.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_PACKAGES_SOURCED:-}" ]] && return 0
readonly DOTFILES_PACKAGES_SOURCED=1

# Tools installed on every platform and in every mode.
readonly -a COMMON_PACKAGES=(git curl wget tmux htop vim neovim ripgrep fzf stow shellcheck)

install_packages() {
    print_section "Installing Packages"

    if [[ -z "${PACKAGE_MANAGER:-}" || "$PACKAGE_MANAGER" == "unknown" ]]; then
        print_warn "Package manager not detected — skipping package installation"
        return 1
    fi

    local -a packages=("${COMMON_PACKAGES[@]}")

    if is_headless; then
        print_status "Server/minimal mode: skipping GUI packages"
    fi

    case "$PACKAGE_MANAGER" in
        pacman)
            packages+=(fd bat eza)
            [[ "${MINIMAL_MODE:-false}" == false ]] && packages+=(base-devel)
            [[ "${SERVER_MODE:-false}" == true ]] &&
                packages+=(nginx docker docker-compose fail2ban ufw certbot certbot-nginx)
            is_headless || packages+=(libx11 libxft libxinerama)
            ;;
        apt)
            packages+=(fd-find bat)
            [[ "${MINIMAL_MODE:-false}" == false ]] && packages+=(build-essential)
            [[ "${SERVER_MODE:-false}" == true ]] &&
                packages+=(nginx docker.io docker-compose fail2ban ufw certbot python3-certbot-nginx)
            is_headless || packages+=(libx11-dev libxft-dev libxinerama-dev)
            # eza only exists in newer repos; add it when available.
            if apt-cache show eza >/dev/null 2>&1; then
                packages+=(eza)
            else
                print_warn "eza not available in configured repos, skipping"
            fi
            ;;
        dnf)
            packages+=(fd-find bat eza)
            [[ "${MINIMAL_MODE:-false}" == false ]] && packages+=(@development-tools)
            [[ "${SERVER_MODE:-false}" == true ]] &&
                packages+=(nginx docker docker-compose fail2ban firewalld certbot python3-certbot-nginx)
            is_headless || packages+=(libX11-devel libXft-devel libXinerama-devel)
            ;;
        zypper)
            packages+=(fd bat)
            [[ "${MINIMAL_MODE:-false}" == false ]] && packages+=(patterns-devel-base-devel_basis)
            [[ "${SERVER_MODE:-false}" == true ]] && packages+=(nginx docker fail2ban firewalld certbot)
            is_headless || packages+=(libX11-devel libXft-devel libXinerama-devel)
            ;;
        apk)
            packages+=(fd bat)
            [[ "${MINIMAL_MODE:-false}" == false ]] && packages+=(build-base)
            [[ "${SERVER_MODE:-false}" == true ]] && packages+=(nginx docker fail2ban certbot)
            is_headless || packages+=(libx11-dev libxft-dev libxinerama-dev)
            ;;
        brew)
            packages+=(fd bat eza)
            if [[ "${SERVER_MODE:-false}" == true ]]; then
                packages+=(nginx docker fail2ban)
                print_warn "Some server packages need extra setup on macOS"
            fi
            ;;
        *)
            print_warn "Unsupported package manager: $PACKAGE_MANAGER"
            return 1
            ;;
    esac

    # Packages contributed by the active profile, appended last so a profile
    # can add to any distro's list without duplicating it.
    if [[ ${#PROFILE_EXTRA_PACKAGES[@]} -gt 0 ]]; then
        packages+=("${PROFILE_EXTRA_PACKAGES[@]}")
        print_status "Profile '${ACTIVE_PROFILE}' adds: ${PROFILE_EXTRA_PACKAGES[*]}"
    fi

    print_status "Packages (${#packages[@]}): ${packages[*]}"

    if is_dry_run; then
        print_dry "install ${#packages[@]} package(s) via ${PACKAGE_MANAGER}"
        return 0
    fi

    # Package installs need root; fail loudly rather than half-installing.
    case "$PACKAGE_MANAGER" in
        pacman) sudo pacman -S --noconfirm --needed "${packages[@]}" ;;
        # noninteractive: debconf/needrestart prompts would block unattended runs.
        apt)    sudo apt-get update && sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}" ;;
        dnf)    sudo dnf install -y "${packages[@]}" ;;
        zypper) sudo zypper --non-interactive install "${packages[@]}" ;;
        apk)    sudo apk add "${packages[@]}" ;;
        brew)   brew install "${packages[@]}" ;;
    esac || {
        print_error "Package installation failed"
        return 1
    }

    [[ "$PACKAGE_MANAGER" == apt ]] && link_renamed_binaries

    print_ok "Package installation completed"
}

# Debian/Ubuntu install fd and bat as `fdfind` and `batcat` (name clashes in
# their archive). The shell config calls the upstream names, including from
# FZF_DEFAULT_COMMAND where aliases do not apply, so link them into
# ~/.local/bin. Never replaces anything already there.
link_renamed_binaries() {
    local pair renamed upstream src
    for pair in fdfind:fd batcat:bat; do
        renamed="${pair%%:*}" upstream="${pair#*:}"
        src=$(command -v "$renamed" 2>/dev/null) || continue
        [[ -e "$HOME/.local/bin/$upstream" || -L "$HOME/.local/bin/$upstream" ]] && continue

        if is_dry_run; then
            print_dry "link ~/.local/bin/$upstream → $src"
            continue
        fi

        mkdir -p "$HOME/.local/bin"
        ln -s "$src" "$HOME/.local/bin/$upstream" && print_ok "Linked $upstream → $src"
    done
    return 0
}
