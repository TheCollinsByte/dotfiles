#!/usr/bin/env bash
# lib/symlinks.sh — Backup, symlink creation, validation, and restore.
#
# Every filesystem mutation that touches $HOME goes through this module.
# create_symlink() is the only sanctioned way to link a config into place.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_SYMLINKS_SOURCED:-}" ]] && return 0
readonly DOTFILES_SYMLINKS_SOURCED=1

# Manifest of every symlink this run created, written into the backup dir so
# --restore knows what to undo. Populated by create_symlink().
BACKUP_MANIFEST=""

# Manifest lines recorded before the backup directory existed.
#
# The directory is only created when something is actually displaced, but
# symlinks may be created before that happens. Those entries are buffered here
# and flushed once the directory appears, so the manifest is complete
# regardless of the order the symlink map happens to be in.
MANIFEST_PENDING=()

# BACKUP_DIR and DOTFILES_DIR are owned by install.sh and set before any
# function here runs.
# shellcheck disable=SC2153

# ========================
# Backups
# ========================

# Create the backup directory on first actual use.
#
# Deliberately lazy: the previous implementation ran `mkdir -p "$BACKUP_DIR"`
# unconditionally in main(), which littered $HOME with empty
# .dotfiles_backup_<ts>/ directories on every --help, --check and --dry-run.
ensure_backup_dir() {
    is_dry_run && return 0
    [[ -d "$BACKUP_DIR" ]] && return 0

    mkdir -p "$BACKUP_DIR" || { print_error "Cannot create backup dir: $BACKUP_DIR"; return 1; }

    BACKUP_MANIFEST="${BACKUP_DIR}/.manifest"
    {
        printf '# dotfiles backup manifest\n'
        printf '# created: %s\n' "$(date -Iseconds)"
        printf '# source:  %s\n' "${DOTFILES_DIR}"
        printf '# format:  <action><TAB><path>\n'
    } > "$BACKUP_MANIFEST"

    # Flush anything recorded before the directory existed.
    if [[ ${#MANIFEST_PENDING[@]} -gt 0 ]]; then
        printf '%s\n' "${MANIFEST_PENDING[@]}" >> "$BACKUP_MANIFEST"
        MANIFEST_PENDING=()
    fi
}

# Record an action in the restore manifest.
# action is "backed_up" (original saved) or "linked" (we created a new symlink).
#
# Buffers the entry when no backup directory exists yet — creating one just to
# hold a manifest would litter $HOME on installs that displace nothing.
record_manifest() {
    local action="$1" path="$2"
    is_dry_run && return 0

    if [[ -n "$BACKUP_MANIFEST" && -f "$BACKUP_MANIFEST" ]]; then
        printf '%s\t%s\n' "$action" "$path" >> "$BACKUP_MANIFEST"
    else
        MANIFEST_PENDING+=("$(printf '%s\t%s' "$action" "$path")")
    fi
}

# Move an existing file/dir out of the way, preserving its path under BACKUP_DIR.
backup_file() {
    local file="$1"

    [[ -e "$file" || -L "$file" ]] || return 0

    if is_dry_run; then
        print_dry "back up ${file} to ${BACKUP_DIR}"
        return 0
    fi

    ensure_backup_dir || return 1

    # Path relative to $HOME so the backup mirrors the home layout and
    # --restore can reverse it unambiguously.
    local rel="${file#"$HOME"/}"
    local dest="${BACKUP_DIR}/${rel}"

    mkdir -p "$(dirname "$dest")"
    if mv "$file" "$dest" 2>/dev/null; then
        print_status "Backed up ${file}"
        record_manifest "backed_up" "$rel"
    else
        print_warn "Could not back up ${file}"
        return 1
    fi
}

# ========================
# Symlinks
# ========================

# Confirm a symlink exists and resolves to the expected source.
validate_symlink() {
    local dst="$1" expected_src="$2"

    if [[ ! -L "$dst" ]]; then
        print_error "Validation failed: $dst is not a symlink"
        return 1
    fi

    local actual expected
    actual=$(readlink -f "$dst" 2>/dev/null) || true
    expected=$(readlink -f "$expected_src" 2>/dev/null) || true

    if [[ "$actual" != "$expected" ]]; then
        print_error "Validation failed: $dst points to $actual instead of $expected"
        return 1
    fi

    return 0
}

# Create or update a symlink.
#
#   create_symlink <src> <dst>
#
# - relative <src> is resolved against $DOTFILES_DIR
# - missing sources are skipped rather than producing broken links
# - idempotent: an existing correct link is a no-op
# - anything in the way is backed up first
# - the result is validated before being reported as success
# - honors DRY_RUN
create_symlink() {
    local src="$1" dst="$2"

    [[ $src == /* ]] || src="${DOTFILES_DIR}/${src}"

    if [[ ! -e "$src" ]]; then
        print_warn "Source not found, skipping: $src"
        return 1
    fi

    # Already correct? Nothing to do.
    if [[ -L "$dst" ]] &&
       [[ "$(readlink -f "$dst" 2>/dev/null)" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
        print_status "Already linked: $dst"
        return 0
    fi

    if is_dry_run; then
        print_dry "link $dst → $src"
        return 0
    fi

    mkdir -p "$(dirname "$dst")"

    if [[ -e "$dst" || -L "$dst" ]]; then
        backup_file "$dst" || return 1
    fi

    if ! ln -sfn "$src" "$dst"; then
        print_error "Failed to create symlink: $dst"
        return 1
    fi

    if validate_symlink "$dst" "$src"; then
        print_ok "Linked $dst → $src"
        record_manifest "linked" "${dst#"$HOME"/}"
    else
        print_warn "Symlink created but validation failed: $dst"
        return 1
    fi
}

# Recursively mirror a directory tree as individual symlinks.
# Skips documentation and VCS metadata.
link_directory() {
    local src_dir="$1" dst_dir="$2"

    [[ -d "$src_dir" ]] || { print_error "Source directory not found: $src_dir"; return 1; }

    is_dry_run || mkdir -p "$dst_dir"

    local item
    while IFS= read -r item; do
        local dst="${dst_dir}/${item##*/}"
        if [[ -d "$item" ]]; then
            link_directory "$item" "$dst"
        else
            create_symlink "$item" "$dst"
        fi
    done < <(find "$src_dir" -mindepth 1 -maxdepth 1 \
        -not -name '*.md' -not -name 'README*' -not -name '.git*')
}

# ========================
# Restore
# ========================

# List available backups, newest first.
list_backups() {
    find "$HOME" -maxdepth 1 -type d -name '.dotfiles_backup_*' -printf '%T@ %p\n' 2>/dev/null |
        sort -rn | cut -d' ' -f2-
}

# Number of backups --cleanup keeps.
readonly BACKUP_RETENTION=5

# Remove old backup directories, keeping the newest $BACKUP_RETENTION.
#
# Backups accumulate one per run that replaced a file, and each holds full
# copies of the originals — on a machine that is re-provisioned often they add
# up. The newest are kept because those are the ones worth rolling back to.
cleanup_backups() {
    print_section "Cleaning Up Old Backups"

    local -a backups=()
    local dir
    while IFS= read -r dir; do
        [[ -n "$dir" ]] && backups+=("$dir")
    done < <(list_backups)

    local total=${#backups[@]}

    if [[ $total -eq 0 ]]; then
        print_ok "No backups to clean up"
        return 0
    fi

    if [[ $total -le $BACKUP_RETENTION ]]; then
        print_ok "${total} backup(s) present, keeping the newest ${BACKUP_RETENTION} — nothing to remove"
        return 0
    fi

    local -a stale=("${backups[@]:$BACKUP_RETENTION}")

    # Total size of what would be freed, in human-readable form.
    local freed
    freed=$(du -shc "${stale[@]}" 2>/dev/null | tail -1 | cut -f1) || freed="unknown"

    print_status "Found ${total} backup(s); ${#stale[@]} older than the newest ${BACKUP_RETENTION}:"
    for dir in "${stale[@]}"; do
        echo "    - ${dir##*/}"
    done
    print_status "Reclaiming approximately ${freed}"

    if is_dry_run; then
        print_dry "remove ${#stale[@]} old backup directory/directories"
        return 0
    fi

    confirm "Permanently delete these ${#stale[@]} backup(s)?" n || {
        print_status "Cleanup cancelled"
        return 0
    }

    local removed=0
    for dir in "${stale[@]}"; do
        if rm -rf "$dir"; then
            removed=$((removed + 1))
        else
            print_warn "Could not remove $dir"
        fi
    done

    print_ok "Removed ${removed} old backup(s)"
    print_status "Kept the newest ${BACKUP_RETENTION}"
}

# Put one backed-up entry back at $target without ever leaving the user with
# neither version: copy beside the target first, then swap, rolling back if
# the swap fails. A plain rm-then-cp loses the live file when cp fails.
restore_one() {
    local file="$1" target="$2"
    local tmp="${target}.dotfiles-restore.$$"
    local prev="${target}.dotfiles-prev.$$"

    cp -a "$file" "$tmp" 2>/dev/null || { rm -rf "$tmp"; return 1; }

    if [[ -e "$target" || -L "$target" ]]; then
        mv -T "$target" "$prev" || { rm -rf "$tmp"; return 1; }
    fi

    if mv -T "$tmp" "$target"; then
        rm -rf "$prev"
        return 0
    fi

    # Swap failed: put the live version back.
    [[ -e "$prev" || -L "$prev" ]] && mv -T "$prev" "$target"
    rm -rf "$tmp"
    return 1
}

# Interactive restoration from a previous backup.
#
# Reverses a run recorded in .manifest: removes symlinks we created, then
# moves the original files back to their recorded locations.
restore_backup() {
    print_section "Restore From Backup"

    local -a backups=()
    while IFS= read -r dir; do
        [[ -n "$dir" ]] && backups+=("$dir")
    done < <(list_backups)

    if [[ ${#backups[@]} -eq 0 ]]; then
        print_warn "No backups found in $HOME"
        print_status "Backups are created automatically when install.sh replaces a file."
        return 1
    fi

    echo ""
    print_status "Available backups:"
    local i
    for i in "${!backups[@]}"; do
        local dir="${backups[$i]}"
        local stamp="${dir##*.dotfiles_backup_}"
        local count
        count=$(find "$dir" -type f -not -name '.manifest' 2>/dev/null | wc -l)
        local integrity="ok"
        [[ -f "$dir/.manifest" ]] || integrity="${YELLOW}no manifest${NC}"
        echo -e "  $((i + 1))) ${stamp}  (${count} file(s), ${integrity})"
    done
    echo ""

    local choice
    read -rp "Select a backup to restore (1-${#backups[@]}, or 0 to cancel) [0]: " choice
    choice="${choice:-0}"

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#backups[@]} ]]; then
        print_status "Restore cancelled"
        return 0
    fi

    local backup_dir="${backups[$((choice - 1))]}"
    local manifest="${backup_dir}/.manifest"

    if [[ ! -f "$manifest" ]]; then
        print_warn "This backup has no manifest — files will be copied back, but"
        print_warn "symlinks created by that run cannot be identified and removed."
        confirm "Continue anyway?" n || { print_status "Restore cancelled"; return 0; }
    fi

    print_status "Restoring from: $backup_dir"
    if ! confirm "This overwrites current configs in \$HOME. Proceed?" n; then
        print_status "Restore cancelled"
        return 0
    fi

    # Step 1: remove the symlinks the original run created, so restored
    # regular files are not written through a dangling link.
    if [[ -f "$manifest" ]]; then
        local action path
        while IFS=$'\t' read -r action path; do
            [[ "$action" == "linked" ]] || continue
            local target="${HOME}/${path}"
            if [[ -L "$target" ]]; then
                if is_dry_run; then
                    print_dry "remove symlink $target"
                else
                    rm -f "$target" && print_status "Removed symlink $target"
                fi
            fi
        done < <(grep -v '^#' "$manifest" 2>/dev/null || true)
    fi

    # Step 2: move originals back into place.
    local restored=0 failed=0 file
    while IFS= read -r file; do
        local rel="${file#"$backup_dir"/}"
        [[ "$rel" == ".manifest" ]] && continue
        local target="${HOME}/${rel}"

        if is_dry_run; then
            print_dry "restore $target"
            restored=$((restored + 1))
            continue
        fi

        mkdir -p "$(dirname "$target")"

        if restore_one "$file" "$target"; then
            print_ok "Restored $target"
            restored=$((restored + 1))
        else
            print_error "Failed to restore $target"
            failed=$((failed + 1))
        fi
    done < <(find "$backup_dir" -mindepth 1 \( -type f -o -type l \) 2>/dev/null)

    echo ""
    print_ok "Restored ${restored} item(s)"
    [[ $failed -gt 0 ]] && print_warn "${failed} item(s) failed to restore"
    print_status "Restart your shell to pick up the restored configuration."
}
