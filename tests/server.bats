#!/usr/bin/env bats
#
# Server firewall configuration. These functions run privileged commands, so
# sudo, ufw, firewall-cmd and sshd are replaced by stubs that log their
# arguments, and the module is sourced directly rather than via install.sh.

load helpers/common

setup() {
    setup_sandbox

    STUBS="${TEST_HOME}/stubs"
    CALLS="${TEST_HOME}/calls.log"
    mkdir -p "$STUBS"
    : > "$CALLS"
    export STUBS CALLS

    # sudo runs its arguments unprivileged.
    printf '#!/bin/sh\n[ "$1" = "-n" ] && shift\n[ "$1" = "-v" ] && exit 0\nexec "$@"\n' > "$STUBS/sudo"
    printf '#!/bin/sh\necho "ufw $*" >> "$CALLS"\n' > "$STUBS/ufw"
    # sshd that cannot report its config, unless a test stubs a port.
    printf '#!/bin/sh\nexit 1\n' > "$STUBS/sshd"
    chmod +x "$STUBS"/*

    # Keep the host's sshd_config and SSH session out of the results.
    export SSHD_CONFIG="${TEST_HOME}/no-sshd_config"
    unset SSH_CONNECTION
}

teardown() { teardown_sandbox; }

# Run a server.sh function with the stubs first on PATH.
run_server_fn() {
    run env PATH="$STUBS:$PATH" bash -c "
        set -euo pipefail
        source '$REPO_ROOT/lib/core.sh'
        source '$REPO_ROOT/lib/server.sh'
        $*
    "
}

stub_sshd_port() {
    printf '#!/bin/sh\necho "port %s"\necho "addressfamily any"\n' "$1" > "$STUBS/sshd"
    chmod +x "$STUBS/sshd"
}

@test "ufw allows the port sshd actually listens on" {
    stub_sshd_port 2222

    run_server_fn configure_firewall
    assert_success

    grep -qx "ufw allow 2222/tcp" "$CALLS"
    # The SSH rule must land before the firewall is switched on.
    [ "$(grep -n 'allow 2222/tcp' "$CALLS" | cut -d: -f1)" -lt \
      "$(grep -n 'enable' "$CALLS" | cut -d: -f1)" ]
}

@test "ufw also allows the port of the current SSH session" {
    stub_sshd_port 22

    SSH_CONNECTION="10.0.0.1 50000 10.0.0.2 2022" run_server_fn configure_firewall
    assert_success

    grep -qx "ufw allow 22/tcp" "$CALLS"
    grep -qx "ufw allow 2022/tcp" "$CALLS"
}

@test "ufw falls back to port 22 when the sshd port cannot be read" {
    run_server_fn configure_firewall
    assert_success

    grep -qx "ufw allow 22/tcp" "$CALLS"
}

@test "ssh ports are read from sshd_config when sshd -T is unavailable" {
    printf 'Port 2200\n#Port 9999\n' > "$TEST_HOME/sshd_config"

    run_server_fn "SSHD_CONFIG='$TEST_HOME/sshd_config' detect_ssh_ports"
    assert_success
    [ "$output" = "2200" ]
}
