#!/usr/bin/env bats
#
# Status bar blocks (bin/statusbar/sb-*). Each runs against stubs and fixture
# /sys and /proc trees; see tests/helpers/statusbar.bash.

load helpers/statusbar

setup()    { setup_statusbar; stub notify-send; stub setsid; }
teardown() { teardown_sandbox; }

# --- sb-clock ---------------------------------------------------------------

@test "clock prints weekday, month, day and 24h time" {
    run_block sb-clock
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[A-Z][a-z]{2}\ [A-Z][a-z]{2}\ [0-9]{2}\ [0-9]{2}:[0-9]{2}$ ]]
}

@test "clock left click shows this month's calendar" {
    stub cal 'echo "Su Mo Tu"'
    run_block sb-clock BLOCK_BUTTON=1
    assert_called "notify-send 📅"
    assert_called "Su Mo Tu"
}

@test "clock right click explains itself" {
    run_block sb-clock BLOCK_BUTTON=3
    assert_called "Left click: this month's calendar"
}
