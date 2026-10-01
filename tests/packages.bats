#!/usr/bin/env bats
#
# Package-manager quirks. Debian/Ubuntu ship fd and bat as `fdfind` and
# `batcat`; the shell config (FZF_DEFAULT_COMMAND, fzf previews) calls them
# by their upstream names, so the installer links the upstream names in.

load helpers/common

setup() {
    setup_sandbox
    STUBS="${TEST_HOME}/stubs"
    mkdir -p "$STUBS"
    printf '#!/bin/sh\n' > "$STUBS/fdfind"
    printf '#!/bin/sh\n' > "$STUBS/batcat"
    chmod +x "$STUBS"/*
    export STUBS
}

teardown() { teardown_sandbox; }

run_pkg_fn() {
    run env PATH="$STUBS:/usr/bin:/bin" bash -c "
        set -euo pipefail
        source '$REPO_ROOT/lib/core.sh'
        source '$REPO_ROOT/lib/packages.sh'
        $*
    "
}

@test "debian renamed binaries are linked under their upstream names" {
    run_pkg_fn link_renamed_binaries
    assert_success

    [ "$(readlink "$TEST_HOME/.local/bin/fd")" = "$STUBS/fdfind" ]
    [ "$(readlink "$TEST_HOME/.local/bin/bat")" = "$STUBS/batcat" ]
}

@test "an existing fd or bat is left alone" {
    mkdir -p "$TEST_HOME/.local/bin"
    echo mine > "$TEST_HOME/.local/bin/fd"

    run_pkg_fn link_renamed_binaries
    assert_success

    [ ! -L "$TEST_HOME/.local/bin/fd" ]
    [ "$(cat "$TEST_HOME/.local/bin/fd")" = mine ]
}

@test "linking renamed binaries is dry-run safe" {
    run_pkg_fn "DRY_RUN=true link_renamed_binaries"
    assert_success
    assert_not_exists "$TEST_HOME/.local/bin"
}
