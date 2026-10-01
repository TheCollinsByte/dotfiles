#!/usr/bin/env bats
#
# DISPLAY discovery in envars.sh, for shells started before X (tmux panes)
# or outside it.

load helpers/common

setup() {
    setup_sandbox
    export X11_SOCKET_DIR="$TEST_HOME/x11"
    mkdir -p "$X11_SOCKET_DIR"
    unset DISPLAY SSH_CONNECTION
}
teardown() { teardown_sandbox; }

# A real unix socket, like the one Xorg creates for display :N.
make_x_socket() {
    python3 -c "import socket,sys; socket.socket(socket.AF_UNIX).bind(sys.argv[1])" "$X11_SOCKET_DIR/X$1"
}

display_after_envars() {
    run sh -c ". '$REPO_ROOT/config/shell/envars.sh'; printf '%s' \"\${DISPLAY:-<unset>}\""
}

@test "a shell without DISPLAY finds the user's running X server" {
    make_x_socket 0
    display_after_envars
    [ "$output" = ":0" ]
}

@test "an existing DISPLAY is left alone" {
    make_x_socket 0
    DISPLAY=:7 display_after_envars
    [ "$output" = ":7" ]
}

@test "SSH sessions do not grab the local display" {
    make_x_socket 0
    SSH_CONNECTION="10.0.0.1 5000 10.0.0.2 22" display_after_envars
    [ "$output" = "<unset>" ]
}

@test "no X server leaves DISPLAY unset" {
    display_after_envars
    [ "$output" = "<unset>" ]
}

@test "a plain file is not mistaken for an X socket" {
    : > "$X11_SOCKET_DIR/X0"
    display_after_envars
    [ "$output" = "<unset>" ]
}
