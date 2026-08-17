#!/usr/bin/env bats
#
# Named installation profiles: loading, mode presets, config skipping, and the
# guard that stops a profile name from escaping the profiles directory.

load helpers/common

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

# --- listing ----------------------------------------------------------------

@test "--list-profiles shows every shipped profile" {
    run_install --list-profiles
    assert_success
    assert_output_contains "full"
    assert_output_contains "home"
    assert_output_contains "work"
    assert_output_contains "minimal"
}

@test "--list-profiles shows descriptions" {
    run_install --list-profiles
    assert_success
    assert_output_contains "Headless"
}

# --- loading ----------------------------------------------------------------

@test "a valid profile loads" {
    run_install --dry-run --profile work --dotfiles
    assert_success
    assert_output_contains "Profile 'work' loaded"
}

@test "an unknown profile fails and lists the valid ones" {
    run_install --profile nonexistent --dotfiles
    assert_failure
    assert_output_contains "Unknown profile"
    assert_output_contains "work"
}

@test "--profile without a name fails" {
    run_install --profile
    assert_failure
    assert_output_contains "requires a name"
}

# --- security ---------------------------------------------------------------

@test "a path traversal in the profile name is rejected" {
    # Profile files are sourced, so a traversal would execute arbitrary code
    # from outside the repository.
    run_install --profile ../../etc/passwd --dotfiles
    assert_failure
    assert_output_contains "Invalid profile name"
}

@test "an absolute path as a profile name is rejected" {
    run_install --profile /etc/passwd --dotfiles
    assert_failure
    assert_output_contains "Invalid profile name"
}

@test "a profile name with a slash is rejected" {
    run_install --profile foo/bar --dotfiles
    assert_failure
    assert_output_contains "Invalid profile name"
}

@test "a profile name with a semicolon is rejected" {
    run_install --profile 'x;id' --dotfiles
    assert_failure
    assert_output_contains "Invalid profile name"
}

# --- behaviour --------------------------------------------------------------

@test "the minimal profile presets server and minimal mode" {
    run_install --dry-run --profile minimal --dotfiles
    assert_success
    assert_output_contains "SERVER mode"
    assert_output_contains "MINIMAL mode"
}

@test "the work profile skips the cmus config" {
    run_install --dry-run --profile work --dotfiles
    assert_success
    assert_output_contains "skips cmus"
}

@test "a skipped config is not linked" {
    run_install --profile work --dotfiles
    assert_success
    assert_not_exists "$TEST_HOME/.config/cmus"
}

@test "configs not skipped by the profile are still linked" {
    run_install --profile work --dotfiles
    assert_success
    assert_symlink "$TEST_HOME/.config/shell"
    assert_symlink "$TEST_HOME/.bashrc"
}

@test "the full profile skips nothing" {
    run_install --profile full --dotfiles
    assert_success
    assert_symlink "$TEST_HOME/.config/cmus"
}

@test "an explicit flag overrides the profile" {
    # full presets SERVER_MODE=false, but --server on the command line wins.
    run_install --dry-run --profile full --server --dotfiles
    assert_success
    assert_output_contains "SERVER mode"
}

@test "a profile contributes its extra packages" {
    run_install --dry-run --profile work --packages
    assert_success
    assert_output_contains "Profile 'work' adds"
    assert_output_contains "docker"
}
