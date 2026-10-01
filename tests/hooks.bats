#!/usr/bin/env bats
#
# The pre-commit hook's built-in secret check (the fallback used when
# gitleaks is not installed).

load helpers/common

setup() {
    setup_sandbox
    REPO="${TEST_HOME}/repo"
    git init -q "$REPO"
    cp "$REPO_ROOT/.githooks/pre-commit" "$REPO/hook"
}

teardown() { teardown_sandbox; }

# PATH without gitleaks, so the fallback check runs.
run_hook() {
    run env PATH=/usr/bin:/bin bash -c "cd '$REPO' && ./hook"
}

@test "a staged private key is blocked even in a large diff" {
    # A big diff after the match makes git still be writing when grep -q
    # exits; under pipefail that SIGPIPE used to read as "no match".
    { echo "-----BEGIN RSA PRIVATE KEY-----"; seq 1 200000; } > "$REPO/key.txt"
    git -C "$REPO" add key.txt

    run_hook
    assert_failure
    assert_output_contains "private key"
}

@test "a clean staged file passes the secret check" {
    echo "hello" > "$REPO/notes.txt"
    git -C "$REPO" add notes.txt

    run_hook
    assert_success
}
