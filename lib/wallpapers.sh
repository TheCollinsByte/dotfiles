#!/usr/bin/env bash
# lib/wallpapers.sh — Optional curated wallpaper download (--wallpapers).
#
# The source repo is ~1.4 GB, so only the chosen categories are fetched with
# a shallow, blob-filtered, sparse checkout. Nothing is committed here: the
# images have no single license and stay a local download.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_WALLPAPERS_SOURCED:-}" ]] && return 0
readonly DOTFILES_WALLPAPERS_SOURCED=1

readonly WALLPAPER_REPO="${DOTFILES_WALLPAPER_REPO:-https://github.com/AngelJumbo/gruvbox-wallpapers.git}"
readonly -a WALLPAPER_CATEGORIES=(minimalistic)
readonly WALLPAPER_DEST="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/gruvbox"

fetch_wallpapers() {
    print_section "Wallpapers"

    local -a paths=()
    local category
    for category in "${WALLPAPER_CATEGORIES[@]}"; do
        paths+=("wallpapers/$category")
    done

    if is_dry_run; then
        print_dry "fetch ${WALLPAPER_CATEGORIES[*]} wallpapers into $WALLPAPER_DEST"
        return 0
    fi

    confirm "Download gruvbox wallpapers (${WALLPAPER_CATEGORIES[*]}, ~58 MB) to $WALLPAPER_DEST?" y ||
        { print_status "Wallpaper download skipped"; return 0; }

    command_exists git || { print_error "git is required to fetch wallpapers"; return 1; }

    if [[ -d "$WALLPAPER_DEST/.git" ]]; then
        print_status "Updating wallpapers..."
        # A depth-1 clone has no shared history to fast-forward from, so fetch
        # the new tip and reset to it; this directory is a read-only mirror.
        git -C "$WALLPAPER_DEST" sparse-checkout set "${paths[@]}" &&
            git -C "$WALLPAPER_DEST" fetch -q --depth 1 origin &&
            git -C "$WALLPAPER_DEST" reset -q --hard FETCH_HEAD ||
            { print_error "Wallpaper update failed"; return 1; }
    elif [[ -e "$WALLPAPER_DEST" && -n "$(ls -A "$WALLPAPER_DEST" 2>/dev/null)" ]]; then
        # Never clone over (or clean up) a folder the user filled themselves.
        print_error "$WALLPAPER_DEST exists and is not a wallpaper checkout — move it aside first"
        return 1
    else
        print_status "Fetching wallpapers..."
        mkdir -p "$(dirname "$WALLPAPER_DEST")"
        git clone -q --depth 1 --filter=blob:none --sparse "$WALLPAPER_REPO" "$WALLPAPER_DEST" &&
            git -C "$WALLPAPER_DEST" sparse-checkout set "${paths[@]}" ||
            { print_error "Wallpaper download failed"; rm -rf "$WALLPAPER_DEST"; return 1; }
    fi

    local count
    count=$(find "$WALLPAPER_DEST/wallpapers" -type f 2>/dev/null | wc -l)
    print_ok "Wallpapers ready: ${count} image(s) in $WALLPAPER_DEST"
    print_status "Shuffle with Super+w or wallpaper-shuffle.sh"
}
