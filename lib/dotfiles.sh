#!/usr/bin/env bash
# lib/dotfiles.sh — Symlinking configs into $HOME.
#
# The symlink map lives here in a single "source:destination" array. Adding a
# new config means adding a line to that array — never an ad-hoc
# create_symlink() call elsewhere.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_DOTFILES_SOURCED:-}" ]] && return 0
readonly DOTFILES_DOTFILES_SOURCED=1

setup_dotfiles() {
    print_section "Setting Up Dotfiles"

    local dir
    for dir in "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/state"; do
        is_dry_run || mkdir -p "$dir"
    done

    # Core configs, installed in every mode. Format: "source:destination".
    local -a dotfiles=(
        "$DOTFILES_DIR/.bashrc:$HOME/.bashrc"
        "$DOTFILES_DIR/.bash_profile:$HOME/.bash_profile"
        "$DOTFILES_DIR/.vimrc:$HOME/.vimrc"
        "$DOTFILES_DIR/.gitconfig:$HOME/.gitconfig"
        "$DOTFILES_DIR/.tmux.conf:$HOME/.tmux.conf"

        "$DOTFILES_DIR/config/bat:$HOME/.config/bat"
        "$DOTFILES_DIR/config/htop:$HOME/.config/htop"
        "$DOTFILES_DIR/config/nvim:$HOME/.config/nvim"
        "$DOTFILES_DIR/config/shell:$HOME/.config/shell"
        "$DOTFILES_DIR/config/ranger:$HOME/.config/ranger"
    )

    # GUI configs, skipped on servers and in minimal mode.
    if is_headless; then
        print_status "Server/minimal mode: skipping GUI configuration files"
    else
        dotfiles+=(
            "$DOTFILES_DIR/.xinitrc:$HOME/.xinitrc"
            "$DOTFILES_DIR/.Xresources:$HOME/.Xresources"
            "$DOTFILES_DIR/.dmenurc:$HOME/.dmenurc"
            "$DOTFILES_DIR/config/cmus:$HOME/.config/cmus"
            "$DOTFILES_DIR/config/fontconfig:$HOME/.config/fontconfig"
            "$DOTFILES_DIR/suckless:$HOME/.config/suckless"
        )
    fi

    # ${entry%%:*} = source, ${entry#*:} = destination.
    local entry dst
    for entry in "${dotfiles[@]}"; do
        dst="${entry#*:}"

        if profile_skips_config "$dst"; then
            print_status "Profile '${ACTIVE_PROFILE}' skips ${dst##*/}"
            continue
        fi

        create_symlink "${entry%%:*}" "$dst" || true
    done

    link_bin_scripts
    ensure_gitconfig_local
    ensure_tmux_plugin_manager

    print_ok "Dotfiles setup complete"
}

# Expose bin/ scripts on PATH via ~/.local/bin without flattening the repo.
link_bin_scripts() {
    [[ -d "$DOTFILES_DIR/bin" ]] || return 0

    print_status "Linking bin scripts..."
    is_dry_run || mkdir -p "$HOME/.local/bin"

    local script
    for script in "$DOTFILES_DIR/bin"/*; do
        [[ -e "$script" ]] || continue
        create_symlink "$script" "$HOME/.local/bin/$(basename "$script")" || true
    done
}

# Machine-specific git identity lives outside the repo so it is never committed.
ensure_gitconfig_local() {
    [[ -f "$HOME/.gitconfig.local" ]] && return 0

    if is_dry_run; then
        print_dry "create ~/.gitconfig.local template"
        return 0
    fi

    print_status "Creating ~/.gitconfig.local template"
    cat > "$HOME/.gitconfig.local" <<'EOF'
# Local Git configuration — machine-specific, never committed.
# .gitconfig includes this file; put your identity and any private settings here.

[user]
	name = Your Name
	email = your.email@example.com
EOF
    chmod 600 "$HOME/.gitconfig.local"
    print_warn "Edit ~/.gitconfig.local with your name and email"
}

ensure_tmux_plugin_manager() {
    [[ -d "$HOME/.tmux/plugins/tpm" ]] && return 0

    if is_dry_run; then
        print_dry "clone tmux plugin manager to ~/.tmux/plugins/tpm"
        return 0
    fi

    if ! command_exists git; then
        print_warn "git missing — skipping tmux plugin manager"
        return 0
    fi

    print_status "Installing tmux plugin manager..."
    if git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null; then
        print_ok "tmux plugin manager installed"
    else
        print_warn "Failed to install tmux plugin manager"
    fi
}
