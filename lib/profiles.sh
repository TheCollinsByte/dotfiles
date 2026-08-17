#!/usr/bin/env bash
# lib/profiles.sh — Named installation profiles.
#
# A profile is a small declarative file in profiles/ that presets the mode
# flags, adds extra packages, and skips configs that do not belong on a
# particular kind of machine. It exists so `--profile work` replaces having to
# remember which combination of flags a given machine needs.
#
# shellcheck shell=bash
#
# ACTIVE_PROFILE and the mode flags are consumed by other modules and by
# install.sh, so their use is not visible from this file.
# shellcheck disable=SC2034

[[ -n "${DOTFILES_PROFILES_SOURCED:-}" ]] && return 0
readonly DOTFILES_PROFILES_SOURCED=1

# Name of the active profile, empty when none was requested.
ACTIVE_PROFILE=""

# Set by a profile file; consumed by packages.sh and dotfiles.sh.
PROFILE_DESCRIPTION=""
PROFILE_EXTRA_PACKAGES=()
PROFILE_SKIP_CONFIGS=()

profiles_dir() { echo "${DOTFILES_DIR}/profiles"; }

# List the available profile names, one per line.
list_profiles() {
    local dir
    dir="$(profiles_dir)"
    [[ -d "$dir" ]] || return 0

    local file
    for file in "$dir"/*.profile; do
        [[ -f "$file" ]] || continue
        basename "$file" .profile
    done
}

# Print available profiles with their descriptions.
show_profiles() {
    print_section "Available Profiles"

    local -a names=()
    local name
    while IFS= read -r name; do
        [[ -n "$name" ]] && names+=("$name")
    done < <(list_profiles)

    if [[ ${#names[@]} -eq 0 ]]; then
        print_warn "No profiles found in $(profiles_dir)"
        return 1
    fi

    local desc
    for name in "${names[@]}"; do
        # Read the description without executing the file, so `--list-profiles`
        # never runs profile code.
        desc=$(grep -m1 '^PROFILE_DESCRIPTION=' "$(profiles_dir)/${name}.profile" 2>/dev/null |
            cut -d= -f2- | tr -d '"'"'" || true)
        printf '  %-10s %s\n' "$name" "${desc:-no description}"
    done
}

# Load a profile by name, applying its settings to the current run.
load_profile() {
    local name="$1"

    # Reject anything that is not a bare profile name. The file is sourced, so
    # a traversal like ../../etc/something would otherwise execute arbitrary
    # code from outside the repository.
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid profile name: $name"
        return 1
    fi

    local file
    file="$(profiles_dir)/${name}.profile"

    if [[ ! -f "$file" ]]; then
        print_error "Unknown profile: $name"
        echo ""
        show_profiles || true
        return 1
    fi

    # Reset, so loading a second profile cannot inherit the first one's lists.
    PROFILE_DESCRIPTION=""
    PROFILE_EXTRA_PACKAGES=()
    PROFILE_SKIP_CONFIGS=()

    # shellcheck source=/dev/null
    source "$file" || { print_error "Failed to load profile: $file"; return 1; }

    ACTIVE_PROFILE="$name"

    # Profiles may preset the mode flags, but an explicit command-line flag
    # always wins — parse_args applies profiles before re-applying flags.
    [[ "${PROFILE_SERVER_MODE:-false}" == true ]]  && SERVER_MODE=true
    [[ "${PROFILE_MINIMAL_MODE:-false}" == true ]] && MINIMAL_MODE=true

    print_ok "Profile '$name' loaded${PROFILE_DESCRIPTION:+ — $PROFILE_DESCRIPTION}"

    [[ ${#PROFILE_EXTRA_PACKAGES[@]} -gt 0 ]] &&
        print_status "Profile adds ${#PROFILE_EXTRA_PACKAGES[@]} package(s): ${PROFILE_EXTRA_PACKAGES[*]}"
    [[ ${#PROFILE_SKIP_CONFIGS[@]} -gt 0 ]] &&
        print_status "Profile skips: ${PROFILE_SKIP_CONFIGS[*]}"

    return 0
}

# True when the given config destination should be skipped by the active
# profile. Matching is on the destination's basename (e.g. ".xinitrc", "cmus").
profile_skips_config() {
    local target="$1"
    [[ ${#PROFILE_SKIP_CONFIGS[@]} -eq 0 ]] && return 1

    local base="${target##*/}"
    local skip
    for skip in "${PROFILE_SKIP_CONFIGS[@]}"; do
        [[ "$base" == "$skip" ]] && return 0
    done
    return 1
}
