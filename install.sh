#!/usr/bin/env bash
#
# Dotfiles installer.
#
# A thin entry point: resolves the repo location, loads lib/*.sh, parses
# arguments and dispatches. All real work lives in the lib modules so each
# concern can be read, tested and shellchecked in isolation.
#
#   ./install.sh --help      for usage
#   ./install.sh --dry-run --all   to preview everything
#
# https://github.com/TheCollinsByte/dotfiles

set -euo pipefail

readonly DOTFILES_VERSION="3.1.0"

# ========================
# Bootstrap
# ========================

# Resolve the real directory of this script, following symlinks so the
# installer works when invoked through a link on PATH.
_resolve_root() {
    local source="${BASH_SOURCE[0]}" dir
    while [[ -L "$source" ]]; do
        dir=$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)
        source=$(readlink "$source")
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd
}

DOTFILES_DIR="$(_resolve_root)"
readonly LIB_DIR="${DOTFILES_DIR}/lib"

if [[ ! -d "$LIB_DIR" ]]; then
    echo "ERROR: lib/ not found at $LIB_DIR — is the repository complete?" >&2
    exit 1
fi

# Order matters: core.sh defines the print_* helpers everything else uses.
# shellcheck source=lib/core.sh
source "${LIB_DIR}/core.sh"

for _module in profiles location symlinks system packages dotfiles suckless server update ui; do
    # shellcheck source=/dev/null
    source "${LIB_DIR}/${_module}.sh" ||
        { echo "ERROR: failed to load lib/${_module}.sh" >&2; exit 1; }
done
unset _module

# ========================
# State
# ========================

BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Declared here, consumed by the lib modules — no in-file use to detect.
# shellcheck disable=SC2034
{
    SYSTEM_TYPE=""
    DISTRO=""
    PACKAGE_MANAGER=""
    CUSTOM_LOCATION=false
}

DRY_RUN=false
SERVER_MODE=false
MINIMAL_MODE=false
ASSUME_YES=${ASSUME_YES:-false}

# Exit status for the whole run. Diagnostic commands (--check, --health-check)
# set this so callers can branch on the result:
#
#   ./install.sh --health-check && echo healthy
#
# Action commands deliberately do not, since a partial failure there is
# reported inline and should not abort a longer argument list.
FINAL_STATUS=0

# ========================
# Composite actions
# ========================

# The full install, shared by --all and the interactive menu.
run_full_install() {
    install_packages || print_warn "Package installation had problems, continuing"
    setup_dotfiles

    if [[ "$SERVER_MODE" == true ]]; then
        configure_server_services
    elif [[ "$MINIMAL_MODE" == true ]]; then
        print_status "Minimal mode: skipping suckless tools"
    else
        setup_suckless_repos
        build_suckless || print_warn "Some suckless builds failed"
    fi

    health_check || true
}

# ========================
# Argument parsing
# ========================

# Options that must run before any state is touched and then exit immediately.
handle_early_exit_flags() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help)    show_usage; exit 0 ;;
            -V|--version) echo "dotfiles ${DOTFILES_VERSION}"; exit 0 ;;
        esac
    done
}

parse_args() {
    # First pass: profile, then mode flags. A profile may preset the modes, so
    # it is applied first and explicit flags override it afterwards.
    local i=1 arg
    while [[ $i -le $# ]]; do
        arg="${!i}"
        if [[ "$arg" == "--profile" ]]; then
            local next=$((i + 1))
            [[ $next -le $# ]] || die "--profile requires a name (try --list-profiles)"
            load_profile "${!next}" || exit 1
        fi
        i=$((i + 1))
    done

    for arg in "$@"; do
        case "$arg" in
            --dry-run|--dry) DRY_RUN=true ;;
            -s|--server)     SERVER_MODE=true ;;
            -m|--minimal)    MINIMAL_MODE=true ;;
            -y|--yes)        ASSUME_YES=true ;;
        esac
    done

    is_dry_run                  && print_warn "DRY-RUN: no changes will be made"
    [[ "$SERVER_MODE" == true ]]  && print_status "SERVER mode: GUI components skipped"
    [[ "$MINIMAL_MODE" == true ]] && print_status "MINIMAL mode: essentials only"

    detect_system

    # Second pass: commands, executed in the order given.
    local ran_command=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            # Mode flags already consumed above.
            --dry-run|--dry|-s|--server|-m|--minimal|-y|--yes) shift ;;
            # Profile already loaded above; skip the flag and its argument.
            --profile) shift 2 ;;

            --list-profiles) show_profiles || true; ran_command=true; shift ;;
            --cleanup)       cleanup_backups || true; ran_command=true; shift ;;

            -l|--location)     prompt_dotfiles_location; ran_command=true; shift ;;
            --set-location)
                [[ -n "${2:-}" ]] || die "--set-location requires a path argument"
                move_dotfiles "$(expand_path "$2")"
                ran_command=true
                shift 2
                ;;

            -c|--check)          check_dependencies || FINAL_STATUS=1; ran_command=true; shift ;;
            -H|--health-check)   health_check       || FINAL_STATUS=1; ran_command=true; shift ;;
            -u|--update)         update_dotfiles || true;    ran_command=true; shift ;;
            -p|--packages)       install_packages || true;   ran_command=true; shift ;;
            -d|--dotfiles)       setup_dotfiles;             ran_command=true; shift ;;
            --restore)           restore_backup || true;     ran_command=true; shift ;;
            --show-log)          show_last_log || true;      ran_command=true; shift ;;
            --server-config)     configure_server_services;  ran_command=true; shift ;;

            -r|--suckless-repos)
                if is_headless; then
                    print_warn "Skipping submodule setup in server/minimal mode"
                else
                    setup_suckless_repos
                fi
                ran_command=true
                shift
                ;;
            -b|--suckless-build)
                if is_headless; then
                    print_warn "Skipping suckless build in server/minimal mode"
                else
                    build_suckless || true
                fi
                ran_command=true
                shift
                ;;

            -a|--all) run_full_install; ran_command=true; shift ;;

            *) print_error "Unknown option: $1"; echo ""; show_usage; exit 1 ;;
        esac
    done

    # Only mode flags were given (e.g. `./install.sh --server`) — fall through
    # to the menu rather than silently doing nothing.
    [[ "$ran_command" == false ]] && run_interactive_menu
    return 0
}

# ========================
# Main
# ========================

main() {
    # --help / --version must work even on a broken or partial install, so
    # they run before logging, location loading and system detection.
    handle_early_exit_flags "$@"

    init_logging "$@"

    load_location_preference
    cd "$DOTFILES_DIR" || die "Cannot enter $DOTFILES_DIR"

    if [[ $# -gt 0 ]]; then
        parse_args "$@"
    else
        detect_system
        run_interactive_menu
    fi

    print_summary
    exit "$FINAL_STATUS"
}

print_summary() {
    echo ""
    print_ok "Done"

    # Only mention backups when something was actually backed up.
    if [[ -d "$BACKUP_DIR" ]] && [[ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        print_warn "Backups saved to: $BACKUP_DIR"
        print_status "Roll back with: ./install.sh --restore"
    fi

    [[ -n "${LOG_FILE:-}" ]] && print_status "Log: $LOG_FILE"

    echo -e "\n${GREEN}Restart your shell to apply changes.${NC}"
}

main "$@"
