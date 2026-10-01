#!/usr/bin/env bash
# tests/helpers/statusbar.bash — hermetic environment for bin/ script tests.
#
# Scripts run with PATH limited to stubs plus a small set of real core
# utilities, so a tool installed on the host (wpctl, playerctl, notify-send)
# can never leak into a test, and "tool missing" is testable.
#
# shellcheck shell=bash
# shellcheck disable=SC2154

load helpers/common

# Real utilities the scripts may use; everything else must be stubbed.
BASE_TOOLS=(sh bash cat awk sed grep date printf cut head tail tr sleep rm
            mkdir mv cp wc expr ls basename dirname find shuf sort env kill
            seq id readlink touch tee iconv)

setup_statusbar() {
    setup_sandbox
    STUBS="${TEST_HOME}/stubs"
    BASE_BIN="${TEST_HOME}/base-bin"
    CALLS="${TEST_HOME}/calls.log"
    SB_SYSFS="${TEST_HOME}/sys"
    SB_PROCFS="${TEST_HOME}/proc"
    XDG_RUNTIME_DIR="${TEST_HOME}/run"
    mkdir -p "$STUBS" "$BASE_BIN" "$SB_SYSFS" "$SB_PROCFS" "$XDG_RUNTIME_DIR"
    : > "$CALLS"
    export STUBS BASE_BIN CALLS SB_SYSFS SB_PROCFS XDG_RUNTIME_DIR

    local tool path
    for tool in "${BASE_TOOLS[@]}"; do
        path=$(command -v "$tool") && ln -s "$path" "$BASE_BIN/$tool"
    done
}

# stub NAME [BODY] — fake command logging its arguments, then running BODY.
stub() {
    local name="$1" body="${2:-}"
    printf '#!/bin/sh\necho "%s $*" >> "$CALLS"\n%s\n' "$name" "$body" > "$STUBS/$name"
    chmod +x "$STUBS/$name"
}

# run_block NAME [VAR=value...] — run a status block hermetically.
run_block() {
    local name="$1"; shift
    run env PATH="$STUBS:$BASE_BIN" "$@" sh "$REPO_ROOT/bin/statusbar/$name"
}

assert_called() {
    if ! grep -qF -- "$1" "$CALLS"; then
        echo "expected a call containing: $1"
        echo "calls: $(cat "$CALLS")"
        return 1
    fi
}

assert_not_called() {
    if grep -q "^$1 " "$CALLS"; then
        echo "expected no call to: $1"
        echo "calls: $(cat "$CALLS")"
        return 1
    fi
}
