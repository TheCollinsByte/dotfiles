#!/usr/bin/env bash
#
# Wallpaper shuffle — pick a random image from the wallpaper sources, set it
# with feh, record the choice, and render the blurred lock-screen image.
#
# Sources (WALLPAPER_DIRS, colon-separated) default to the user's own folder
# and the optional gruvbox set fetched by `install.sh --wallpapers`. The
# folders are only read, never written.

set -euo pipefail

DEFAULT_DIRS="$HOME/.config/wallpapers:${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/gruvbox"
IFS=: read -r -a SOURCES <<< "${WALLPAPER_DIRS:-$DEFAULT_DIRS}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOCK_IMAGE="${XDG_CACHE_HOME:-$HOME/.cache}/lock.png"
LOG_FILE="${STATE_DIR}/wallpaper-shuffle.log"

# Log beside other dotfiles state rather than next to the script: this file is
# symlinked from ~/.local/bin, so `dirname "$0"` resolves back into the repo.
mkdir -p "$STATE_DIR"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

log() { printf '%s wallpaper-shuffle: %s\n' "$(date +%H:%M:%S)" "$1"; }

command -v feh >/dev/null 2>&1 || { log "feh not installed, aborting"; exit 1; }

# Every regular file in every existing source, skipping git metadata.
candidates=()
for dir in "${SOURCES[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' f; do
        candidates+=("$f")
    # wallpaper.png: the copy older versions of this script wrote into the folder.
    done < <(find "$dir" -type f -not -path '*/.git/*' -not -name 'wallpaper.png' -print0)
done

if [[ ${#candidates[@]} -eq 0 ]]; then
    log "no files found in: ${SOURCES[*]}"
    exit 1
fi

# Random order, first real image wins; bounded by the candidate count.
selected=""
while IFS= read -r -d '' candidate; do
    if [[ -s "$candidate" ]] && file --mime-type -b "$candidate" | grep -q '^image/'; then
        selected="$candidate"
        break
    fi
    log "skipping invalid or empty image: $candidate"
done < <(printf '%s\0' "${candidates[@]}" | shuf -z)

if [[ -z "$selected" ]]; then
    log "no valid images found"
    exit 1
fi

log "setting wallpaper: $selected"
feh --no-fehbg --bg-fill "$selected"
printf '%s\n' "$selected" > "$STATE_DIR/wallpaper"

# Pre-render the lock image so locking is instant. Cosmetic: skipped quietly.
if command -v magick >/dev/null 2>&1; then
    size="${SCREEN_SIZE:-}"
    if [[ -z "$size" ]] && command -v xrandr >/dev/null 2>&1; then
        size=$(xrandr 2>/dev/null | awk '/\*/ { print $1; exit }')
    fi
    size="${size:-1920x1080}"
    mkdir -p "$(dirname "$LOCK_IMAGE")"
    tmp="${LOCK_IMAGE%.png}.tmp.png"
    if magick "${selected}[0]" -resize "${size}^" -gravity center -extent "$size" \
            -blur 0x10 -fill black -colorize 35% "$tmp"; then
        mv -f "$tmp" "$LOCK_IMAGE"
        log "rendered lock image ($size)"
    else
        rm -f "$tmp"
        log "lock image render failed; lock will use a solid colour"
    fi
fi
