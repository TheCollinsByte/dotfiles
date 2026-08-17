#!/usr/bin/env bash
# lib/core.sh — Output, logging, and shared primitives.
#
# Sourced by install.sh before every other module. Provides the print_*
# family (the only sanctioned way to emit status), the logging system, and
# small guards used throughout the codebase.
#
# shellcheck shell=bash

# Guard against double-sourcing (readonly re-assignment aborts under set -e).
[[ -n "${DOTFILES_CORE_SOURCED:-}" ]] && return 0
readonly DOTFILES_CORE_SOURCED=1

# ========================
# Colors
# ========================

# Honor NO_COLOR (https://no-color.org/) and non-TTY output, so piping
# install.sh into a file or CI log produces clean, greppable text.
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    readonly RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
else
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    # Used by lib/ui.sh.
    # shellcheck disable=SC2034
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'
fi

# ========================
# Logging
# ========================

# Logs live under XDG_STATE_HOME so they never pollute the repo or $HOME root.
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/logs"
LOG_FILE=""
readonly LOG_RETENTION=10

# Open a timestamped log file for this run.
# Called once from main(). Safe to call when the directory is unwritable —
# logging silently degrades to stdout-only rather than aborting the install.
init_logging() {
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        return 0
    fi

    LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d_%H%M%S).log"

    if ! : > "$LOG_FILE" 2>/dev/null; then
        LOG_FILE=""
        return 0
    fi

    {
        echo "# dotfiles install log"
        echo "# started: $(date -Iseconds)"
        echo "# command: $0 $*"
        echo "# host:    $(uname -srm) / $(hostname 2>/dev/null || echo unknown)"
        echo "# ---"
    } >> "$LOG_FILE"

    prune_old_logs
}

# Keep only the newest $LOG_RETENTION logs.
prune_old_logs() {
    [[ -d "$LOG_DIR" ]] || return 0

    local -a old_logs=()
    # Newest first; everything past the retention count is dropped.
    while IFS= read -r logfile; do
        old_logs+=("$logfile")
    done < <(find "$LOG_DIR" -maxdepth 1 -name 'install-*.log' -type f -printf '%T@ %p\n' 2>/dev/null |
        sort -rn | tail -n "+$((LOG_RETENTION + 1))" | cut -d' ' -f2-)

    [[ ${#old_logs[@]} -eq 0 ]] && return 0
    rm -f "${old_logs[@]}" 2>/dev/null || true
}

# Append a line to the log file, stripped of ANSI escapes.
log_line() {
    [[ -n "$LOG_FILE" ]] || return 0
    printf '%s %s\n' "$(date +%H:%M:%S)" "$1" |
        sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE" 2>/dev/null || true
}

# Print the most recent log file to stdout.
show_last_log() {
    local latest
    latest=$(find "$LOG_DIR" -maxdepth 1 -name 'install-*.log' -type f -printf '%T@ %p\n' 2>/dev/null |
        sort -rn | head -1 | cut -d' ' -f2-)

    if [[ -z "$latest" ]]; then
        print_warn "No logs found in $LOG_DIR"
        return 1
    fi

    print_section "Last Install Log"
    print_status "File: $latest"
    echo ""
    cat "$latest"
}

# ========================
# Output
# ========================

print_section() {
    echo -e "\n${BLUE}==>${NC} ${GREEN}$1${NC}"
    log_line "==> $1"
}

print_status() { echo -e "${BLUE}[*]${NC} $1";        log_line "[*] $1"; }
print_ok()     { echo -e "${GREEN}[✓]${NC} $1";       log_line "[OK] $1"; }
print_warn()   { echo -e "${YELLOW}[!]${NC} $1";      log_line "[WARN] $1"; }
print_error()  { echo -e "${RED}[✗] ERROR:${NC} $1" >&2; log_line "[ERROR] $1"; }

# Emit a "[DRY-RUN] Would ..." line and return success.
# Every filesystem-mutating function calls this instead of hand-rolling the
# prefix, which keeps dry-run output uniform and greppable.
print_dry() { echo -e "${YELLOW}[DRY-RUN]${NC} Would $1"; log_line "[DRY-RUN] Would $1"; }

# ========================
# Guards & helpers
# ========================

command_exists() { command -v "$1" >/dev/null 2>&1; }

# True when the run should not touch the filesystem.
is_dry_run() { [[ "${DRY_RUN:-false}" == true ]]; }

# True when GUI components should be skipped (server or minimal mode).
is_headless() { [[ "${SERVER_MODE:-false}" == true ]] || [[ "${MINIMAL_MODE:-false}" == true ]]; }

# Ask a yes/no question. Returns 0 for yes.
# Non-interactive runs (no TTY, or ASSUME_YES=true) answer with the default
# instead of blocking forever — required for CI and `curl | bash` installs.
confirm() {
    local prompt="$1" default="${2:-n}" reply

    if [[ "${ASSUME_YES:-false}" == true ]]; then
        return 0
    fi

    if [[ ! -t 0 ]]; then
        [[ "$default" == "y" ]]
        return
    fi

    local hint="y/N"
    [[ "$default" == "y" ]] && hint="Y/n"

    read -rp "$(echo -e "${YELLOW}?${NC} ${prompt} (${hint}): ")" reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Expand a leading ~ and normalize the path without requiring it to exist.
expand_path() {
    local path="${1/#\~/$HOME}"
    realpath -m "$path" 2>/dev/null || echo "$path"
}

# Abort with a message. Used for unrecoverable setup errors only.
die() {
    print_error "$1"
    exit "${2:-1}"
}
