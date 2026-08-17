#!/usr/bin/env bash
# lib/location.sh — Dotfiles location selection, relocation, and persistence.
#
# The repo is location-independent: DOTFILES_DIR is resolved from BASH_SOURCE
# and may be moved anywhere. $HOME/.dotfiles_location persists the choice.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_LOCATION_SOURCED:-}" ]] && return 0
readonly DOTFILES_LOCATION_SOURCED=1

readonly LOCATION_PREF_FILE="${HOME}/.dotfiles_location"

# Interactive location chooser.
prompt_dotfiles_location() {
    print_section "Dotfiles Location Setup"

    local current="$DOTFILES_DIR"

    echo -e "${BLUE}Current location:${NC} $current"
    echo ""
    echo "Common locations:"
    echo "  1) $HOME/.dotfiles         (hidden, popular convention)"
    echo "  2) $HOME/dotfiles          (visible, simple)"
    echo "  3) $HOME/.config/dotfiles  (XDG compliant)"
    echo "  4) $HOME/org/dotfiles      (organized)"
    echo "  5) Custom location"
    echo "  6) Keep current location"
    echo ""

    local choice
    read -rp "Select location (1-6) [6]: " choice
    choice="${choice:-6}"

    local new_location=""
    case "$choice" in
        1) new_location="$HOME/.dotfiles" ;;
        2) new_location="$HOME/dotfiles" ;;
        3) new_location="$HOME/.config/dotfiles" ;;
        4) new_location="$HOME/org/dotfiles" ;;
        5) read -rp "Enter custom path: " new_location ;;
        6) print_ok "Keeping current location: $current"; return 0 ;;
        *) print_warn "Invalid choice, keeping current location"; return 0 ;;
    esac

    [[ -n "$new_location" ]] || return 0
    new_location=$(expand_path "$new_location")

    if [[ "$new_location" == "$current" ]]; then
        print_ok "Location unchanged: $current"
        return 0
    fi

    echo ""
    print_status "New location: $new_location"

    if [[ -e "$new_location" ]]; then
        print_error "Location already exists: $new_location"
        confirm "Merge with existing location?" n || {
            print_warn "Keeping current location"
            return 1
        }
    fi

    confirm "Move dotfiles to $new_location?" n || {
        print_warn "Keeping current location"
        return 0
    }

    move_dotfiles "$new_location"
}

# Relocate the repo and repoint every symlink that referenced the old path.
move_dotfiles() {
    local new_location="$1"
    local old_location="$DOTFILES_DIR"

    if [[ "$new_location" == "$old_location" ]]; then
        print_ok "Location unchanged: $old_location"
        return 0
    fi

    if is_dry_run; then
        print_dry "move $old_location → $new_location"
        print_dry "repoint existing symlinks and save the location preference"
        return 0
    fi

    print_status "Moving dotfiles from $old_location to $new_location..."
    mkdir -p "$(dirname "$new_location")"

    if ! mv "$old_location" "$new_location"; then
        print_error "Failed to move dotfiles"
        return 1
    fi

    DOTFILES_DIR="$new_location"
    # Consumed by install.sh; not read within this module.
    # shellcheck disable=SC2034
    CUSTOM_LOCATION=true
    print_ok "Dotfiles moved to: $new_location"

    print_status "Updating existing symlinks..."
    update_symlinks_location "$old_location" "$new_location"

    save_location_preference "$new_location"
}

# Repoint symlinks in $HOME and $HOME/.config from old_location to new_location.
update_symlinks_location() {
    local old_location="$1" new_location="$2"
    local updated=0

    local -a candidates=(
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.vimrc"
        "$HOME/.gitconfig"
        "$HOME/.tmux.conf"
        "$HOME/.xinitrc"
        "$HOME/.Xresources"
        "$HOME/.dmenurc"
    )

    # Include ~/.config entries and ~/.local/bin scripts, which are linked too.
    local entry
    for entry in "$HOME/.config"/* "$HOME/.local/bin"/*; do
        [[ -L "$entry" ]] && candidates+=("$entry")
    done

    local link target new_target
    for link in "${candidates[@]}"; do
        [[ -L "$link" ]] || continue

        target=$(readlink "$link") || continue
        [[ "$target" == "$old_location"* ]] || continue

        new_target="${new_location}${target#"$old_location"}"
        if ln -sfn "$new_target" "$link"; then
            # NOTE: `updated=$((updated + 1))` rather than `((updated++))`.
            # Under `set -e`, post-increment from 0 returns the pre-increment
            # value (0) as its exit status and kills the script — this was a
            # real bug that aborted every relocation on the very first symlink.
            updated=$((updated + 1))
        fi
    done

    if [[ $updated -gt 0 ]]; then
        print_ok "Updated $updated symlink(s)"
    else
        print_status "No symlinks needed updating"
    fi
}

save_location_preference() {
    local location="$1"

    if is_dry_run; then
        print_dry "save location preference to $LOCATION_PREF_FILE"
        return 0
    fi

    echo "$location" > "$LOCATION_PREF_FILE"
    print_status "Location preference saved to $LOCATION_PREF_FILE"
}

# Load a previously saved location, if it still exists.
load_location_preference() {
    [[ -f "$LOCATION_PREF_FILE" ]] || return 0

    local saved
    saved=$(< "$LOCATION_PREF_FILE")

    # Only honor the preference when it points at a real dotfiles checkout;
    # a stale file must not silently redirect the install elsewhere.
    if [[ -d "$saved" && -f "$saved/install.sh" ]]; then
        DOTFILES_DIR="$saved"
    elif [[ -n "$saved" ]]; then
        print_warn "Saved location no longer valid, ignoring: $saved"
    fi
}
