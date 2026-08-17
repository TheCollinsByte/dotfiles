#!/usr/bin/env bats
#
# Health check and dependency check: the diagnostics users rely on when
# something is wrong, so they must not report a broken install as healthy.

load helpers/common

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

# --- dependency check -------------------------------------------------------

@test "--check succeeds on a working machine" {
    run_install --check
    assert_success
    assert_output_contains "dependencies satisfied"
}

@test "--check reports git" {
    run_install --check
    assert_success
    assert_output_contains "git installed"
}

@test "--check warns about files that will be backed up" {
    echo "mine" > "$TEST_HOME/.bashrc"
    run_install --check
    assert_success
    assert_output_contains "will be backed up"
}

@test "--check reports no conflicts on a clean home" {
    run_install --check
    assert_success
    assert_output_contains "No conflicting files"
}

# --- health check -----------------------------------------------------------

@test "health check passes after a minimal install" {
    "$INSTALL" --minimal --dotfiles >/dev/null 2>&1

    run_install --minimal --health-check
    assert_success
    assert_output_contains "Health check"
}

@test "health check reports missing configs before installing" {
    run_install --minimal --health-check
    assert_success
    assert_output_contains "Missing"
}

@test "health check detects a broken symlink" {
    "$INSTALL" --minimal --dotfiles >/dev/null 2>&1

    # Repoint a managed link at something that does not exist.
    ln -sfn "$TEST_HOME/nowhere" "$TEST_HOME/.bashrc"

    run_install --minimal --health-check
    assert_failure
    assert_output_contains "Broken symlink"
}

@test "health check flags an unmanaged regular file" {
    "$INSTALL" --minimal --dotfiles >/dev/null 2>&1

    rm "$TEST_HOME/.vimrc"
    echo "hand written" > "$TEST_HOME/.vimrc"

    run_install --minimal --health-check
    assert_success
    assert_output_contains "not a symlink"
}

@test "health check validates shell config syntax" {
    "$INSTALL" --minimal --dotfiles >/dev/null 2>&1

    run_install --minimal --health-check
    assert_success
    assert_output_contains "parses cleanly"
}

@test "health check verifies submodules" {
    run_install --minimal --health-check
    assert_success
    assert_output_contains "Checking submodules"
}

# --- system info ------------------------------------------------------------

@test "detection reports a package manager" {
    run_install --check
    assert_success
    assert_output_contains "Detected"
}
