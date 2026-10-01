#!/usr/bin/env bats
#
# bin/lock, bin/lock-sleep-wrapper and bin/dim-screen.

load helpers/statusbar

setup() {
    setup_statusbar
    export XDG_CACHE_HOME="$TEST_HOME/.cache"
    mkdir -p "$XDG_CACHE_HOME"
    stub notify-send
}
teardown() { teardown_sandbox; }

run_bin() { local name="$1"; shift; run env PATH="$STUBS:$BASE_BIN" "$@" "$REPO_ROOT/bin/$name"; }

@test "lock uses i3lock-color over the cached image" {
    stub i3lock 'case "$1" in --version) echo "i3lock: version 2.13.c.5 © 2010 Michael Stapelberg" ;; esac'
    touch "$XDG_CACHE_HOME/lock.png"
    run_bin lock
    [ "$status" -eq 0 ]
    assert_called "--nofork"
    assert_called "-i $XDG_CACHE_HOME/lock.png"
    assert_called "--clock"
}

@test "lock uses a solid colour without a cached image" {
    stub i3lock 'case "$1" in --version) echo "i3lock: version 2.13.c.5" ;; esac'
    run_bin lock
    assert_called "-c 282828"
}

@test "lock falls back to xtrlock without i3lock-color" {
    stub i3lock 'case "$1" in --version) echo "i3lock: version 2.15 © 2010 Michael Stapelberg" ;; esac'
    stub xtrlock
    run_bin lock
    assert_called "xtrlock -b"
}

@test "lock falls back to xtrlock without any i3lock" {
    stub xtrlock
    run_bin lock
    assert_called "xtrlock -b"
}

@test "lock fails loudly with no locker at all" {
    run_bin lock
    [ "$status" -ne 0 ]
    assert_called "notify-send -u critical"
}

@test "sleep wrapper runs the locker without passing it the inhibitor fd" {
    stub fakelock '[ -e /dev/fd/9 ] && echo "LEAKED" >> "$CALLS"; exit 0'
    : > "$TEST_HOME/inhibit"
    run bash -c "exec 9<'$TEST_HOME/inhibit'; XSS_SLEEP_LOCK_FD=9 PATH='$STUBS:$BASE_BIN' '$REPO_ROOT/bin/lock-sleep-wrapper' fakelock"
    [ "$status" -eq 0 ]
    assert_called "fakelock"
    ! grep -q LEAKED "$CALLS"
}

@test "dim-screen dims, then restores brightness on TERM" {
    mkdir -p "$SB_SYSFS/class/backlight/intel"
    echo 500 > "$SB_SYSFS/class/backlight/intel/brightness"
    echo 1000 > "$SB_SYSFS/class/backlight/intel/max_brightness"
    stub brightnessctl 'case "$*" in *get*) echo 500 ;; esac'

    env PATH="$STUBS:$BASE_BIN" "$REPO_ROOT/bin/dim-screen" &
    local pid=$!
    sleep 0.5
    kill -TERM "$pid"
    wait "$pid" || true

    assert_called "brightnessctl -d intel -q set 10%"
    assert_called "brightnessctl -d intel -q set 500"
}

@test "dim-screen is a no-op without a backlight" {
    stub brightnessctl
    run_bin dim-screen
    [ "$status" -eq 0 ]
    assert_not_called brightnessctl
}

@test "lock passes a cache path with spaces as one argument" {
    export XDG_CACHE_HOME="$TEST_HOME/my cache"
    mkdir -p "$XDG_CACHE_HOME"; touch "$XDG_CACHE_HOME/lock.png"
    stub i3lock 'case "$1" in --version) echo "i3lock: version 2.13.c.5" ;; *) for a; do echo "ARG:$a" >> "$CALLS"; done ;; esac'
    run_bin lock
    grep -qx "ARG:$XDG_CACHE_HOME/lock.png" "$CALLS"
}

@test "dim-screen never brightens an already dim screen" {
    mkdir -p "$SB_SYSFS/class/backlight/intel"
    echo 50 > "$SB_SYSFS/class/backlight/intel/brightness"
    echo 1000 > "$SB_SYSFS/class/backlight/intel/max_brightness"
    stub brightnessctl 'case "$*" in *get*) echo 50 ;; esac'
    env PATH="$STUBS:$BASE_BIN" "$REPO_ROOT/bin/dim-screen" &
    local pid=$!
    # It should exit on its own; TERM it only if it is (wrongly) still running.
    sleep 0.5; kill -TERM "$pid" 2>/dev/null || true; wait "$pid" || true
    ! grep -q "set 10%" "$CALLS"
}
