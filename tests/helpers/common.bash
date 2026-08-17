#!/usr/bin/env bash
# tests/helpers/common.bash — shared setup and assertions for the bats suite.
#
# Every test runs the real installer against a throwaway $HOME so that no test
# can touch the developer's actual configuration.
#
# shellcheck shell=bash
#
# $status and $output are set by bats' `run`, not by this file.
# shellcheck disable=SC2154

# Repo root, derived from the test file's location.
export REPO_ROOT="${BATS_TEST_DIRNAME}/.."
export INSTALL="${REPO_ROOT}/install.sh"

# Create an isolated $HOME and point the installer at it.
#
# NO_COLOR keeps assertions free of ANSI escapes; ASSUME_YES stops any prompt
# from blocking a non-interactive run.
setup_sandbox() {
    TEST_HOME="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/dotfiles-home.XXXXXX")"
    export TEST_HOME
    export HOME="$TEST_HOME"
    export NO_COLOR=1
    export ASSUME_YES=true

    # Logs and state must land inside the sandbox too.
    export XDG_STATE_HOME="${TEST_HOME}/.local/state"
}

teardown_sandbox() {
    [[ -n "${TEST_HOME:-}" && -d "$TEST_HOME" ]] && rm -rf "$TEST_HOME"
    return 0
}

# Run the installer inside the sandbox.
run_install() {
    run "$INSTALL" "$@"
}

# --- assertions -------------------------------------------------------------

assert_success() {
    if [[ "$status" -ne 0 ]]; then
        echo "expected success, got exit $status"
        echo "output: $output"
        return 1
    fi
}

assert_failure() {
    if [[ "$status" -eq 0 ]]; then
        echo "expected failure, got exit 0"
        echo "output: $output"
        return 1
    fi
}

assert_output_contains() {
    if [[ "$output" != *"$1"* ]]; then
        echo "expected output to contain: $1"
        echo "actual output: $output"
        return 1
    fi
}

assert_output_not_contains() {
    if [[ "$output" == *"$1"* ]]; then
        echo "expected output NOT to contain: $1"
        echo "actual output: $output"
        return 1
    fi
}

assert_symlink() {
    if [[ ! -L "$1" ]]; then
        echo "expected a symlink at: $1"
        [[ -e "$1" ]] && echo "  (exists, but is not a symlink)"
        return 1
    fi
    if [[ ! -e "$1" ]]; then
        echo "symlink is dangling: $1 -> $(readlink "$1")"
        return 1
    fi
}

assert_not_exists() {
    if [[ -e "$1" || -L "$1" ]]; then
        echo "expected nothing at: $1"
        return 1
    fi
}

assert_file_contains() {
    local file="$1" needle="$2"
    if [[ ! -f "$file" ]]; then
        echo "file does not exist: $file"
        return 1
    fi
    if ! grep -q -- "$needle" "$file"; then
        echo "expected $file to contain: $needle"
        echo "actual: $(cat "$file")"
        return 1
    fi
}

# Count backup directories in the sandbox home.
count_backups() {
    find "$TEST_HOME" -maxdepth 1 -type d -name '.dotfiles_backup_*' 2>/dev/null | wc -l
}
