#!/usr/bin/env bash
# lib/update.sh — Pull the repo and refresh submodules.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_UPDATE_SOURCED:-}" ]] && return 0
readonly DOTFILES_UPDATE_SOURCED=1

update_dotfiles() {
    print_section "Updating Dotfiles"

    cd "$DOTFILES_DIR" || { print_error "Cannot enter $DOTFILES_DIR"; return 1; }

    command_exists git || { print_error "git is required to update"; return 1; }

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        print_error "Not a git repository — cannot update"
        return 1
    fi

    # Resolve the branch once and quote it everywhere. The previous code
    # interpolated $(git branch --show-current) unquoted into several git
    # commands, which broke on any branch name containing whitespace.
    local branch
    branch=$(git branch --show-current) || branch=""
    if [[ -z "$branch" ]]; then
        print_error "Detached HEAD — check out a branch before updating"
        return 1
    fi

    # An unconfigured upstream made the old `HEAD..origin/$branch` comparison
    # fail hard; detect it up front and report something actionable.
    local upstream
    if ! upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null); then
        print_error "Branch '$branch' has no upstream configured"
        print_status "Fix with: git branch --set-upstream-to=origin/$branch $branch"
        return 1
    fi

    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        print_warn "You have uncommitted changes:"
        git status --short
        echo ""
        confirm "Continue with update?" n || { print_status "Update cancelled"; return 0; }
    fi

    print_status "Fetching from origin..."
    if is_dry_run; then
        print_dry "fetch origin and fast-forward '$branch' to '$upstream'"
        print_dry "update all submodules"
        return 0
    fi

    git fetch origin || { print_error "Failed to fetch from origin"; return 1; }

    local behind
    behind=$(git rev-list --count "HEAD..${upstream}" 2>/dev/null) || behind=0

    if [[ "$behind" -eq 0 ]]; then
        print_ok "Already up to date"
        print_status "Refreshing submodules..."
        git submodule update --init --recursive && print_ok "Submodules refreshed"
        return 0
    fi

    print_status "'$branch' is $behind commit(s) behind $upstream"
    echo ""
    print_status "Incoming changes:"
    git --no-pager log --oneline "HEAD..${upstream}" | head -10
    echo ""

    confirm "Apply these updates?" n || { print_status "Update cancelled"; return 0; }

    print_status "Pulling changes..."
    if git pull --ff-only origin "$branch"; then
        print_ok "Dotfiles updated"
    else
        print_error "Pull failed (local commits may have diverged from upstream)"
        return 1
    fi

    print_status "Updating submodules..."
    if git submodule update --init --recursive --remote --merge; then
        print_ok "Submodules updated"
    else
        print_warn "Some submodules failed to update"
    fi

    print_ok "Update complete"
    print_status "Run './install.sh --dotfiles' to apply any new configuration"
}
