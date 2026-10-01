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

# --- sb-disk ----------------------------------------------------------------

@test "disk shows root usage" {
    stub df 'printf "Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/x 100 61 39 61%% /\n"'
    run_block sb-disk
    [ "$output" = "💾 61%" ]
}

@test "disk warns at 90%" {
    stub df 'printf "Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/x 100 93 7 93%% /\n"'
    run_block sb-disk
    [ "$output" = "⚠ 93%" ]
}

@test "disk left click notifies a df summary" {
    stub df 'printf "Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/x 100 61 39 61%% /\n"'
    run_block sb-disk BLOCK_BUTTON=1
    assert_called "df -h"
    assert_called "notify-send 💾 Disks"
}

# --- sb-kbd -----------------------------------------------------------------

@test "keyboard block hides with a single layout" {
    stub setxkbmap 'echo "layout:     gb"'
    run_block sb-kbd
    [ -z "$output" ]
}

@test "keyboard block shows the active layout of several" {
    stub setxkbmap 'echo "layout:     us,ru"'
    run_block sb-kbd
    [ "$output" = "⌨ us" ]
}

@test "keyboard click rotates layouts" {
    stub setxkbmap 'echo "layout:     us,ru"'
    run_block sb-kbd BLOCK_BUTTON=1
    assert_called "setxkbmap -layout ru,us"
}

# --- sb-brightness ----------------------------------------------------------

make_backlight() {   # name brightness max
    mkdir -p "$SB_SYSFS/class/backlight/$1"
    echo "$2" > "$SB_SYSFS/class/backlight/$1/brightness"
    echo "$3" > "$SB_SYSFS/class/backlight/$1/max_brightness"
}

@test "brightness hides without a backlight" {
    run_block sb-brightness
    [ -z "$output" ]
}

@test "brightness shows percent of the first backlight only" {
    make_backlight a_intel 70 100
    make_backlight b_acpi 5 10
    run_block sb-brightness
    [ "$output" = "💡 70%" ]
}

@test "brightness scroll adjusts by 5%" {
    make_backlight intel 50 100
    stub brightnessctl
    run_block sb-brightness BLOCK_BUTTON=4
    assert_called "brightnessctl -q set 5%+"
    run_block sb-brightness BLOCK_BUTTON=5
    assert_called "brightnessctl -q set 5%-"
}
