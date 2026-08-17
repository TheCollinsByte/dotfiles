#!/usr/bin/env bash
#
# Wallpaper shuffle — pick a random valid PNG from the wallpaper directory
# and set it as the desktop background with feh.

set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG_FILE="${LOG_DIR}/wallpaper-shuffle.log"

# Log beside other dotfiles state rather than next to the script: this file is
# symlinked from ~/.local/bin, so `dirname "$0"` resolves back into the repo
# and every run would write a stray log into the working tree.
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

log() { printf '%s wallpaper-shuffle: %s\n' "$(date +%H:%M:%S)" "$1"; }

command -v feh >/dev/null 2>&1 || { log "feh not installed, aborting"; exit 1; }

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    log "wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Collect candidates with find + null delimiters so filenames containing
# spaces or newlines are handled correctly.
mapfile -d '' -t wallpapers < <(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f -name '*.png' \
        -not -name 'wallpaper.png' -print0
)

if [[ ${#wallpapers[@]} -eq 0 ]]; then
    log "no PNG files found in $WALLPAPER_DIR"
    exit 1
fi

# Try candidates in random order, stopping at the first valid image.
# Bounded by the candidate count, so a directory full of corrupt files exits
# cleanly instead of spinning forever as the previous `while true` loop did.
selected=""
while IFS= read -r -d '' candidate; do
    if [[ -s "$candidate" ]] && file --mime-type -b "$candidate" | grep -q '^image/'; then
        selected="$candidate"
        break
    fi
    log "skipping invalid or empty image: $candidate"
done < <(printf '%s\0' "${wallpapers[@]}" | shuf -z)

if [[ -z "$selected" ]]; then
    log "no valid images found in $WALLPAPER_DIR"
    exit 1
fi

log "setting wallpaper: $selected"
cp -- "$selected" "$WALLPAPER_DIR/wallpaper.png"
feh --no-fehbg --bg-scale "$WALLPAPER_DIR/wallpaper.png"
