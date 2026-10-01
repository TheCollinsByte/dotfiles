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

# --- sb-volume --------------------------------------------------------------

@test "volume hides when no audio server answers" {
    stub wpctl 'exit 1'
    run_block sb-volume
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "volume shows level with a matching icon" {
    stub wpctl 'echo "Volume: 0.45"'
    run_block sb-volume
    [ "$output" = "🔉 45%" ]
    stub wpctl 'echo "Volume: 0.80"'
    run_block sb-volume
    [ "$output" = "🔊 80%" ]
}

@test "volume shows muted" {
    stub wpctl 'echo "Volume: 0.45 [MUTED]"'
    run_block sb-volume
    [ "$output" = "🔇 45%" ]
}

@test "volume click mutes and scroll changes level" {
    stub wpctl 'echo "Volume: 0.45"'
    run_block sb-volume BLOCK_BUTTON=1
    assert_called "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
    run_block sb-volume BLOCK_BUTTON=4
    assert_called "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
    run_block sb-volume BLOCK_BUTTON=5
    assert_called "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
}

# --- sb-battery -------------------------------------------------------------

make_battery() {   # name capacity status
    mkdir -p "$SB_SYSFS/class/power_supply/$1"
    echo "$2" > "$SB_SYSFS/class/power_supply/$1/capacity"
    echo "$3" > "$SB_SYSFS/class/power_supply/$1/status"
}

@test "battery hides without a battery" {
    run_block sb-battery
    [ -z "$output" ]
}

@test "battery hides when full on AC" {
    make_battery BAT0 100 Full
    run_block sb-battery
    [ -z "$output" ]
}

@test "battery held at a charge threshold shows plainly" {
    make_battery BAT0 80 "Not charging"
    run_block sb-battery
    [ "$output" = "🔋 80%" ]
    assert_not_called notify-send
}

@test "battery shows charging and discharging, first battery only" {
    make_battery BAT0 82 Charging
    make_battery BAT1 10 Discharging
    run_block sb-battery
    [ "$output" = "⚡ 82%" ]
}

@test "battery low icon below 20%" {
    make_battery BAT0 15 Discharging
    run_block sb-battery
    [ "$output" = "🪫 15%" ]
}

@test "battery critical notification fires once per discharge" {
    make_battery BAT0 8 Discharging
    run_block sb-battery
    run_block sb-battery
    [ "$(grep -c 'notify-send -u critical' "$CALLS")" -eq 1 ]

    # Charging clears the flag, so the next discharge warns again.
    make_battery BAT0 8 Charging
    run_block sb-battery
    make_battery BAT0 8 Discharging
    run_block sb-battery
    [ "$(grep -c 'notify-send -u critical' "$CALLS")" -eq 2 ]
}

# --- sb-internet ------------------------------------------------------------

make_iface() {   # name operstate
    mkdir -p "$SB_SYSFS/class/net/$1"
    echo "$2" > "$SB_SYSFS/class/net/$1/operstate"
}

@test "internet shows wifi strength" {
    make_iface wlan0 up
    mkdir -p "$SB_PROCFS/net"
    printf 'Inter-| sta-|   Quality\n face | tus | link level noise\n wlan0: 0000   49.  -61.  -256\n' > "$SB_PROCFS/net/wireless"
    run_block sb-internet
    [ "$output" = "📶 70%" ]
}

@test "internet shows ethernet when wifi is down" {
    make_iface wlan0 down
    make_iface enp0s31f6 up
    run_block sb-internet
    [ "$output" = "🌐" ]
}

@test "internet shows offline" {
    make_iface wlan0 down
    run_block sb-internet
    [ "$output" = "❌" ]
}

@test "internet click opens nmtui" {
    make_iface wlan0 down
    run_block sb-internet BLOCK_BUTTON=1 TERMINAL=st
    assert_called "setsid -f st -e nmtui"
}

# --- sb-music ---------------------------------------------------------------

@test "music hides with no player" {
    stub playerctl 'exit 1'
    run_block sb-music
    [ -z "$output" ]
}

@test "music shows playing track" {
    stub playerctl 'case "$1" in status) echo Playing ;; metadata) echo "Daft Punk – Contact" ;; esac'
    run_block sb-music
    [ "$output" = "▶ Daft Punk – Contact" ]
}

@test "music shows paused" {
    stub playerctl 'case "$1" in status) echo Paused ;; metadata) echo "A – B" ;; esac'
    run_block sb-music
    [ "$output" = "⏸ A – B" ]
}

@test "music truncates long titles to 30 characters, valid UTF-8 under C locale" {
    stub playerctl 'case "$1" in status) echo Playing ;; metadata) echo "Sigur Rós – Hoppípolla Hoppípolla Hoppípolla" ;; esac'
    run_block sb-music LC_ALL=C LANG=
    local text="${output#▶ }"
    [ "$(printf '%s' "$text" | LC_ALL=C.UTF-8 wc -m)" -le 30 ]
    printf '%s' "$text" | iconv -f UTF-8 -t UTF-8 >/dev/null
    [[ "$text" == *… ]]
}

@test "music clicks control the player" {
    stub playerctl 'case "$1" in status) echo Playing ;; metadata) echo "A – B" ;; esac'
    run_block sb-music BLOCK_BUTTON=1
    assert_called "playerctl play-pause"
    run_block sb-music BLOCK_BUTTON=4
    assert_called "playerctl next"
    run_block sb-music BLOCK_BUTTON=5
    assert_called "playerctl previous"
}

@test "cpu stale sample with idle outpacing total stays within 0-100" {
    # Stored sample from another boot: total and idle both lower, idle far lower.
    echo "1000 100" > "$XDG_RUNTIME_DIR/sb-cpu"
    write_stat "10 0 0 1500 0 0 0 0 0 0"        # total 1510, idle 1500
    run_block sb-cpu
    [ "$output" = "💻 0%" ]
}

@test "battery reporting Full below 95% hides (worn battery on AC)" {
    make_battery BAT0 93 Full
    run_block sb-battery
    [ -z "$output" ]
}
