#!/usr/bin/env bats
#
# Argument parsing, help/version, and the invariants that must hold before the
# installer touches anything.

load helpers/common

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

# --- early-exit flags -------------------------------------------------------

@test "--help prints usage and exits 0" {
    run_install --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "--dry-run"
}

@test "--version prints a version string" {
    run_install --version
    assert_success
    assert_output_contains "dotfiles"
}

@test "--help does not create any state" {
    run_install --help
    assert_success
    # No backup dir, no log dir, no generated files: --help must work on a
    # broken install without side effects.
    [ "$(count_backups)" -eq 0 ]
    assert_not_exists "$TEST_HOME/.gitconfig.local"
    assert_not_exists "$TEST_HOME/.local/state/dotfiles"
}

@test "--version does not create any state" {
    run_install --version
    assert_success
    [ "$(count_backups)" -eq 0 ]
    assert_not_exists "$TEST_HOME/.local/state/dotfiles"
}

# --- unknown options --------------------------------------------------------

@test "unknown option fails and shows usage" {
    run_install --definitely-not-an-option
    assert_failure
    assert_output_contains "Unknown option"
    assert_output_contains "Usage:"
}

@test "--set-location without a path fails" {
    run_install --set-location
    assert_failure
    assert_output_contains "requires a path"
}

# --- mode flags -------------------------------------------------------------

@test "flag order does not matter: --all --server == --server --all" {
    run_install --dry-run --server --all
    assert_success
    local server_first="$output"

    run_install --dry-run --all --server
    assert_success

    # Both must report server mode and skip GUI configs. The old parser applied
    # commands in order, so --all ran before --server was seen.
    assert_output_contains "SERVER mode"
    [[ "$server_first" == *"SERVER mode"* ]]
}

@test "--server skips GUI configuration" {
    run_install --dry-run --server --dotfiles
    assert_success
    assert_output_contains "skipping GUI configuration"
    assert_output_not_contains ".xinitrc"
}

@test "--minimal skips GUI configuration" {
    run_install --dry-run --minimal --dotfiles
    assert_success
    assert_output_contains "skipping GUI configuration"
}

@test "desktop mode does link GUI configuration" {
    run_install --dry-run --dotfiles
    assert_success
    assert_output_contains ".xinitrc"
}

# --- logging ----------------------------------------------------------------

@test "a normal run writes a log" {
    run_install --check
    assert_success
    local logs
    logs=$(find "$TEST_HOME/.local/state/dotfiles/logs" -name 'install-*.log' 2>/dev/null | wc -l)
    [ "$logs" -ge 1 ]
}

@test "--show-log reports when no logs exist" {
    # A fresh sandbox has no logs, but the run itself creates one, so this
    # asserts --show-log succeeds rather than crashing on an empty directory.
    run_install --show-log
    assert_success
}

@test "logs are pruned to the retention limit" {
    mkdir -p "$TEST_HOME/.local/state/dotfiles/logs"
    for i in $(seq 1 15); do
        touch -d "2020-01-01 00:00:$i" \
            "$TEST_HOME/.local/state/dotfiles/logs/install-2020010${i}_000000.log"
    done

    run_install --version
    # --version exits before logging, so force a logging run.
    run_install --check
    assert_success

    local count
    count=$(find "$TEST_HOME/.local/state/dotfiles/logs" -name 'install-*.log' | wc -l)
    [ "$count" -le 10 ]
}

# --- colour -----------------------------------------------------------------

@test "NO_COLOR output contains no ANSI escapes" {
    run_install --help
    assert_success
    # $'\033' is an ESC; none should survive with NO_COLOR set.
    [[ "$output" != *$'\033'* ]]
}
