#!/usr/bin/env bats
#
# Repository relocation and the location preference file.
#
# These tests copy the repo into the sandbox first, because relocation moves
# the directory it is run from.

load helpers/common

setup() {
    setup_sandbox

    # A minimal but complete copy of the repo to relocate.
    REPO_COPY="${TEST_HOME}/src/dotfiles"
    mkdir -p "$REPO_COPY"
    cp -a "$REPO_ROOT/install.sh" "$REPO_ROOT/lib" "$REPO_ROOT/profiles" "$REPO_COPY/"
    cp -a "$REPO_ROOT/.bashrc" "$REPO_ROOT/.vimrc" "$REPO_ROOT/.tmux.conf" \
          "$REPO_ROOT/.bash_profile" "$REPO_ROOT/.gitconfig" "$REPO_COPY/"
    mkdir -p "$REPO_COPY/config"
    cp -a "$REPO_ROOT/config/shell" "$REPO_COPY/config/"
    export REPO_COPY
}

teardown() { teardown_sandbox; }

# --- preference file --------------------------------------------------------

@test "moving the repo saves a location preference" {
    run "$REPO_COPY/install.sh" --set-location "$TEST_HOME/moved"
    assert_success

    [ -d "$TEST_HOME/moved" ]
    assert_file_contains "$TEST_HOME/.dotfiles_location" "$TEST_HOME/moved"
}

@test "a stale location preference is ignored with a warning" {
    echo "$TEST_HOME/does-not-exist" > "$TEST_HOME/.dotfiles_location"

    run "$REPO_COPY/install.sh" --check
    assert_success
    assert_output_contains "no longer valid"
}

@test "a preference pointing at a non-dotfiles directory is ignored" {
    mkdir -p "$TEST_HOME/not-dotfiles"
    echo "$TEST_HOME/not-dotfiles" > "$TEST_HOME/.dotfiles_location"

    # The directory exists but has no install.sh, so it must not be adopted.
    run "$REPO_COPY/install.sh" --check
    assert_success
    assert_output_contains "no longer valid"
}

# --- relocation -------------------------------------------------------------

@test "relocation repoints existing symlinks" {
    # Install from the original location.
    "$REPO_COPY/install.sh" --minimal --dotfiles >/dev/null 2>&1
    assert_symlink "$TEST_HOME/.bashrc"

    local before
    before="$(readlink "$TEST_HOME/.bashrc")"
    [[ "$before" == "$REPO_COPY"* ]]

    # Move it.
    run "$REPO_COPY/install.sh" --set-location "$TEST_HOME/relocated"
    assert_success

    # The symlink must now point into the new location and still resolve.
    # This is the regression that ((updated++)) used to break: under set -e it
    # returned non-zero on the first increment and killed the script.
    local after
    after="$(readlink "$TEST_HOME/.bashrc")"
    [[ "$after" == "$TEST_HOME/relocated"* ]]
    assert_symlink "$TEST_HOME/.bashrc"
}

@test "relocation reports how many symlinks it updated" {
    "$REPO_COPY/install.sh" --minimal --dotfiles >/dev/null 2>&1

    run "$REPO_COPY/install.sh" --set-location "$TEST_HOME/relocated"
    assert_success
    assert_output_contains "Updated"
}

@test "relocating to the same path is a no-op" {
    run "$REPO_COPY/install.sh" --set-location "$REPO_COPY"
    assert_success
    assert_output_contains "unchanged"
    [ -f "$REPO_COPY/install.sh" ]
}

@test "dry-run relocation does not move anything" {
    run "$REPO_COPY/install.sh" --dry-run --set-location "$TEST_HOME/nope"
    assert_success

    [ -f "$REPO_COPY/install.sh" ]
    assert_not_exists "$TEST_HOME/nope"
}
