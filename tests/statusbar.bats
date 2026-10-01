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

# --- sb-cpu -----------------------------------------------------------------

write_stat() { printf 'cpu  %s\ncpu0 0 0 0 0 0 0 0 0 0 0\n' "$1" > "$SB_PROCFS/stat"; }

@test "cpu first run shows the since-boot average" {
    write_stat "100 0 100 800 0 0 0 0 0 0"      # total 1000, idle 800
    run_block sb-cpu
    [ "$output" = "💻 20%" ]
}

@test "cpu shows usage between samples and warns at 90%" {
    write_stat "100 0 100 800 0 0 0 0 0 0"
    run_block sb-cpu
    write_stat "1000 0 100 900 0 0 0 0 0 0"     # +1000 total, +100 idle
    run_block sb-cpu
    [ "$output" = "🔥 90%" ]
}

@test "cpu counters going backwards fall back to the since-boot average" {
    echo "999999 999999" > "$XDG_RUNTIME_DIR/sb-cpu"   # stale, from another boot
    write_stat "100 0 100 800 0 0 0 0 0 0"
    run_block sb-cpu
    [ "$output" = "💻 20%" ]
}

@test "cpu left click opens htop sorted by cpu" {
    write_stat "100 0 100 800 0 0 0 0 0 0"
    run_block sb-cpu BLOCK_BUTTON=1 TERMINAL=st
    assert_called "setsid -f st -e htop -s PERCENT_CPU"
}

# --- sb-memory --------------------------------------------------------------

write_meminfo() { printf 'MemTotal: %s kB\nMemFree: 1 kB\nMemAvailable: %s kB\n' "$1" "$2" > "$SB_PROCFS/meminfo"; }

@test "memory shows used and total in GiB" {
    write_meminfo 24306728 9874000              # ~23.2G total, ~13.8G used
    run_block sb-memory
    [ "$output" = "🧠 13.8/23.2G" ]
}

@test "memory warns at 90% used" {
    write_meminfo 10485760 1000000
    run_block sb-memory
    [[ "$output" == 🔥* ]]
}

@test "memory left click opens htop sorted by memory" {
    write_meminfo 10485760 5000000
    run_block sb-memory BLOCK_BUTTON=1 TERMINAL=st
    assert_called "setsid -f st -e htop -s PERCENT_MEM"
}
