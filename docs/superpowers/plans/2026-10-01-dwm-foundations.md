# dwm Foundations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the stock dwm desktop into a gruvbox-themed, keyboard-driven environment with a clickable, instant status bar, dunst notifications, an i3lock-color lock screen with auto-lock, and wallpaper management — all reproducible from this repo.

**Architecture:** Shell scripts in `bin/` (status blocks, lock, dim, wallpaper) are tested with bats against stubbed commands and fixture `/sys` and `/proc` trees. C configuration lives in committed `config.h` files inside the dwm, dmenu, st and dwmblocks-async submodule forks. The installer (`lib/*.sh`) gains the dunst link, new packages, an AUR step and a `--wallpapers` flag.

**Tech Stack:** POSIX sh, bash, bats 1.14, shellcheck 0.10, dwm 6.5 + statuscmd + restartsig, dwmblocks-async, dunst, i3lock-color, xss-lock, ImageMagick, feh, wpctl, brightnessctl, playerctl.

**Spec:** `docs/superpowers/specs/2026-10-01-dwm-foundations-design.md`

## Global Constraints

- Mod key: Super (`Mod4Mask`).
- Font: `FiraCode Nerd Font:size=10` (dwm, dmenu, dunst); st uses `FiraCode Nerd Font Mono:pixelsize=14:antialias=true:autohint=true`.
- Palette: bg `#282828`, bg1 `#3c3836`, bg2 `#504945`, fg `#ebdbb2`, gray `#928374`, red `#cc241d`, bright red `#fb4934`, green `#98971a`, yellow `#d79921`, blue `#458588`, aqua `#689d6a`.
- Block scripts are POSIX `sh`, one file per block in `bin/statusbar/`, print nothing to hide, read `/sys` via `${SB_SYSFS:-/sys}` and `/proc` via `${SB_PROCFS:-/proc}`.
- `BLOCK_BUTTON`: 1 = main action, 3 = help notification, 4/5 = scroll up/down.
- Block signals are unique and non-zero: music 1, internet 2, cpu 3, memory 4, disk 5, kbd 6, volume 7, brightness 8, battery 9, clock 10. dwmblocks-async signal N is real-time signal `34+N`.
- Installer invariants (from `CLAUDE.md`): every filesystem mutation dry-run guarded; GUI work gated by `is_headless`; every prompt via `confirm`; `n=$((n + 1))`, never `((n++))`; `local x; x=$(cmd)`; status output only via `print_*`.
- Runtime state goes in `$XDG_RUNTIME_DIR` (fallback `/tmp`) or `$XDG_STATE_HOME/dotfiles`, never next to a script.
- Tools are put on PATH for running bats and shellcheck with:
  `export PATH=/tmp/claude-1000/-home-collo-org-dotfiles/b00803ba-fe20-4aef-90b8-152549d36c4d/scratchpad/bats/bin:/tmp/claude-1000/-home-collo-org-dotfiles/b00803ba-fe20-4aef-90b8-152549d36c4d/scratchpad/shellcheck-v0.10.0:$PATH`
  (or system `bats`/`shellcheck` if installed).

## Review Focus

1. **C locale (dwmblocks started before LANG is set) truncating multibyte music titles** → output must stay valid UTF-8 and ≤ 30 characters. Test in Task 5.
2. **CPU counters lower than the stored sample (state file from a previous boot)** → must not print a negative or >100% value; falls back to the since-boot average. Test in Task 2.
3. **Laptop with two batteries or two backlights** → uses the first device, no concatenated garbage. Tests in Tasks 3 and 4.
4. **Battery held at a charge threshold ("Not charging" at 80%)** → shows `🔋 80%` with no ⚡ and no warning. Test in Task 4.
5. **Wallpaper filenames with spaces** → selected and set correctly. Test in Task 7.

---

## File Structure

| File | Responsibility |
|---|---|
| `tests/helpers/statusbar.bash` | Sandbox, hermetic PATH, command stubs and fixture trees for script tests |
| `bin/statusbar/sb-{clock,cpu,memory,disk,kbd,volume,brightness,battery,internet,music}` | One status block each |
| `bin/lock` | Lock the screen (i3lock-color, fallback xtrlock) |
| `bin/lock-sleep-wrapper` | Hold off suspend until the locker has grabbed the screen |
| `bin/dim-screen` | Idle pre-lock dim, restore on activity |
| `bin/wallpaper-shuffle.sh` | Pick and set wallpaper, record state, render lock image |
| `config/dunst/dunstrc` | Notification theme |
| `lib/wallpapers.sh` | `--wallpapers` sparse download |
| `lib/packages.sh`, `lib/dotfiles.sh`, `lib/ui.sh`, `install.sh` | Packages, AUR step, dunst link, flag wiring |
| `.xinitrc`, `config/shell/aliases.sh` | Session start order, `l` alias |
| `suckless/dwm/config.h` (+ patches) | Keys, look, bar clicks, restart |
| `suckless/dmenu/config.h`, `suckless/st/config.h` | Theme and font |
| `suckless/dwmblocks/config.h` (dwmblocks-async) | Block table |

---

### Task 1: Statusbar test harness and `sb-clock`

**Files:**
- Create: `tests/helpers/statusbar.bash`
- Create: `tests/statusbar.bats`
- Modify: `bin/statusbar/sb-clock` (full rewrite)
- Modify: `Makefile:10-14` (SCRIPTS covers every file under `bin/`)

**Interfaces:**
- Produces (used by Tasks 2–6):
  - `setup_statusbar` — sandbox plus `$STUBS`, `$CALLS`, `$SB_SYSFS`, `$SB_PROCFS`, `$XDG_RUNTIME_DIR`, `$BASE_BIN`, all exported
  - `stub NAME [BODY]` — a fake command that appends `NAME args` to `$CALLS`, then runs BODY
  - `run_block NAME [VAR=value...]` — runs `bin/statusbar/NAME` with `PATH=$STUBS:$BASE_BIN`
  - `assert_called "TEXT"` — passes when a line of `$CALLS` contains TEXT
  - `assert_not_called "NAME"` — passes when no line of `$CALLS` starts with `NAME `

- [ ] **Step 1: Write the harness**

`tests/helpers/statusbar.bash`:

```bash
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
            seq id readlink touch tee)

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
```

- [ ] **Step 2: Write the failing tests**

`tests/statusbar.bats`:

```bash
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
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bats tests/statusbar.bats`
Expected: first test FAILS (current output `2026 Oct 01 (Thu) 🕙 10:41AM` does not match), click tests FAIL (no `cal`, no help text).

- [ ] **Step 4: Rewrite `bin/statusbar/sb-clock`**

```sh
#!/bin/sh
# Clock block. Left click: this month's calendar. Right click: help.

case $BLOCK_BUTTON in
    1) notify-send "📅 $(date '+%B %Y')" "$(cal)" ;;
    3) notify-send "🕙 Clock" "Left click: this month's calendar" ;;
esac

date '+%a %b %d %H:%M'
```

- [ ] **Step 5: Make lint cover every `bin/` file**

In `Makefile`, replace the `SCRIPTS :=` assignment with:

```make
SCRIPTS := install.sh $(wildcard lib/*.sh) $(shell find bin -type f) \
           $(wildcard config/shell/*.sh) $(wildcard profiles/*.profile) \
           tests/helpers/common.bash tests/helpers/statusbar.bash \
           .githooks/pre-commit .bashrc .bash_profile .xinitrc \
           config/ranger/scope.sh
```

- [ ] **Step 6: Run tests and lint**

Run: `bats tests/statusbar.bats && make lint`
Expected: 3 tests PASS, `shellcheck: clean`.

- [ ] **Step 7: Commit**

```bash
git add tests/helpers/statusbar.bash tests/statusbar.bats bin/statusbar/sb-clock Makefile
git commit -m "Add statusbar test harness; rework clock block"
```

---

### Task 2: `sb-cpu` and `sb-memory`

**Files:**
- Create: `bin/statusbar/sb-cpu`
- Modify: `bin/statusbar/sb-memory` (full rewrite)
- Test: `tests/statusbar.bats` (append)

**Interfaces:**
- Consumes: `setup_statusbar`, `stub`, `run_block`, `assert_called` (Task 1).
- Produces: `$XDG_RUNTIME_DIR/sb-cpu` state file, one line `TOTAL IDLE`.

- [ ] **Step 1: Append failing tests**

```bash
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
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/statusbar.bats --filter "cpu|memory"`
Expected: FAIL (`sb-cpu` missing; memory output differs).

- [ ] **Step 3: Create `bin/statusbar/sb-cpu`**

```sh
#!/bin/sh
# CPU usage since the previous refresh. Left click: htop by CPU. Right click: help.

case $BLOCK_BUTTON in
    1) setsid -f "${TERMINAL:-st}" -e htop -s PERCENT_CPU ;;
    3) notify-send "💻 CPU" "Usage since the last refresh.
🔥 at 90% or more.
Left click: htop sorted by CPU" ;;
esac

proc="${SB_PROCFS:-/proc}"
state="${XDG_RUNTIME_DIR:-/tmp}/sb-cpu"

# First line of /proc/stat is the aggregate: cpu user nice system idle iowait irq softirq steal ...
read -r _ user nice system idle iowait irq softirq steal _ < "$proc/stat"
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_all=$((idle + iowait))

prev_total=0 prev_idle=0
[ -r "$state" ] && read -r prev_total prev_idle < "$state"
printf '%s %s\n' "$total" "$idle_all" > "$state"

dt=$((total - prev_total))
di=$((idle_all - prev_idle))
# Counters reset (new boot) or unchanged: use the since-boot average instead.
if [ "$dt" -le 0 ] || [ "$di" -lt 0 ]; then
    dt=$total di=$idle_all
fi
[ "$dt" -gt 0 ] || exit 0

usage=$(( (100 * (dt - di)) / dt ))
icon="💻"
[ "$usage" -ge 90 ] && icon="🔥"
echo "$icon $usage%"
```

Run: `chmod +x bin/statusbar/sb-cpu`

- [ ] **Step 4: Rewrite `bin/statusbar/sb-memory`**

```sh
#!/bin/sh
# Memory used / total. Left click: htop by memory. Right click: help.

case $BLOCK_BUTTON in
    1) setsid -f "${TERMINAL:-st}" -e htop -s PERCENT_MEM ;;
    3) notify-send "🧠 Memory" "Used / total, in GiB.
🔥 at 90% or more.
Left click: htop sorted by memory" ;;
esac

awk '
    /^MemTotal:/     { total = $2 }
    /^MemAvailable:/ { avail = $2 }
    END {
        if (total == 0) exit
        used = total - avail
        icon = (100 * used / total >= 90) ? "🔥" : "🧠"
        printf "%s %.1f/%.1fG\n", icon, used / 1048576, total / 1048576
    }' "${SB_PROCFS:-/proc}/meminfo"
```

- [ ] **Step 5: Run tests**

Run: `bats tests/statusbar.bats`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add bin/statusbar/sb-cpu bin/statusbar/sb-memory tests/statusbar.bats
git commit -m "Add cpu block; rework memory block with warning and click"
```

---

### Task 3: `sb-disk`, `sb-kbd`, `sb-brightness`

**Files:**
- Create: `bin/statusbar/sb-disk`, `bin/statusbar/sb-kbd`
- Modify: `bin/statusbar/sb-brightness` (full rewrite)
- Test: `tests/statusbar.bats` (append)

**Interfaces:**
- Consumes: Task 1 harness.
- Produces: `sb-kbd` signals itself with `kill -40` (34+6); `sb-brightness` uses `brightnessctl -q set 5%+|5%-`.

- [ ] **Step 1: Append failing tests**

```bash
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
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/statusbar.bats --filter "disk|keyboard|brightness"`
Expected: FAIL.

- [ ] **Step 3: Create `bin/statusbar/sb-disk`**

```sh
#!/bin/sh
# Root filesystem usage. Left click: all disks. Right click: help.

mount="${SB_DISK_MOUNT:-/}"

case $BLOCK_BUTTON in
    1) notify-send "💾 Disks" "$(df -h -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null)" ;;
    3) notify-send "💾 Disk" "Usage of $mount.
⚠ at 90% or more.
Left click: usage of every disk" ;;
esac

pct=$(df -P "$mount" 2>/dev/null | awk 'NR == 2 { sub("%", "", $5); print $5 }')
[ -n "$pct" ] || exit 0

icon="💾"
[ "$pct" -ge 90 ] && icon="⚠"
echo "$icon $pct%"
```

- [ ] **Step 4: Create `bin/statusbar/sb-kbd`**

```sh
#!/bin/sh
# Active keyboard layout; hidden with only one. Left click: next layout.

layouts=$(setxkbmap -query 2>/dev/null | awk '/^layout:/ { print $2 }')
case $layouts in
    *,*) ;;
    *) exit 0 ;;
esac

case $BLOCK_BUTTON in
    1)
        # Rotate: the first layout in the list is the active one.
        layouts="${layouts#*,},${layouts%%,*}"
        setxkbmap -layout "$layouts"
        ;;
    3) notify-send "⌨ Keyboard" "Active layout of: $layouts
Left click: switch to the next layout" ;;
esac

echo "⌨ ${layouts%%,*}"
```

- [ ] **Step 5: Rewrite `bin/statusbar/sb-brightness`**

```sh
#!/bin/sh
# Backlight brightness; hidden without a backlight. Scroll: ±5%. Right click: help.

set -- "${SB_SYSFS:-/sys}"/class/backlight/*
[ -r "$1/brightness" ] && [ -r "$1/max_brightness" ] || exit 0

case $BLOCK_BUTTON in
    3) notify-send "💡 Brightness" "Scroll up / down: ±5%" ;;
    4) brightnessctl -q set 5%+ ;;
    5) brightnessctl -q set 5%- ;;
esac

max=$(cat "$1/max_brightness")
[ "$max" -gt 0 ] 2>/dev/null || exit 0
echo "💡 $((100 * $(cat "$1/brightness") / max))%"
```

Run: `chmod +x bin/statusbar/sb-disk bin/statusbar/sb-kbd`

- [ ] **Step 6: Run tests**

Run: `bats tests/statusbar.bats`
Expected: all PASS.

- [ ] **Step 7: Commit**

```bash
git add bin/statusbar/sb-disk bin/statusbar/sb-kbd bin/statusbar/sb-brightness tests/statusbar.bats
git commit -m "Add disk and keyboard blocks; brightness scroll and fixtures"
```

---

### Task 4: `sb-volume` and `sb-battery`

**Files:**
- Modify: `bin/statusbar/sb-volume`, `bin/statusbar/sb-battery` (full rewrites)
- Test: `tests/statusbar.bats` (append)

**Interfaces:**
- Consumes: Task 1 harness.
- Produces: `$XDG_RUNTIME_DIR/sb-battery-warned` flag file.

- [ ] **Step 1: Append failing tests**

```bash
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
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/statusbar.bats --filter "volume|battery"`
Expected: FAIL.

- [ ] **Step 3: Rewrite `bin/statusbar/sb-volume`**

```sh
#!/bin/sh
# Output volume; hidden without an audio server. Left click: mute.
# Scroll: ±5%. Right click: help.

sink="@DEFAULT_AUDIO_SINK@"

case $BLOCK_BUTTON in
    1) wpctl set-mute "$sink" toggle ;;
    3) notify-send "🔊 Volume" "Left click: mute / unmute
Scroll up / down: ±5%" ;;
    4) wpctl set-volume -l 1.0 "$sink" 5%+ ;;
    5) wpctl set-volume "$sink" 5%- ;;
esac

info=$(wpctl get-volume "$sink" 2>/dev/null) || exit 0
[ -n "$info" ] || exit 0

vol=$(echo "$info" | awk '{ printf "%d", $2 * 100 + 0.5 }')
case $info in
    *MUTED*) icon="🔇" ;;
    *) if [ "$vol" -ge 70 ]; then icon="🔊"
       elif [ "$vol" -ge 30 ]; then icon="🔉"
       else icon="🔈"; fi ;;
esac
echo "$icon $vol%"
```

- [ ] **Step 4: Rewrite `bin/statusbar/sb-battery`**

```sh
#!/bin/sh
# Battery charge; hidden without a battery or when full on AC.
# Left click: status and time estimate. Right click: help.

set -- "${SB_SYSFS:-/sys}"/class/power_supply/BAT*
bat="$1"
[ -r "$bat/capacity" ] || exit 0

cap=$(cat "$bat/capacity")
status=$(cat "$bat/status" 2>/dev/null)
flag="${XDG_RUNTIME_DIR:-/tmp}/sb-battery-warned"

# Hours:minutes from energy (µWh) and power (µW), when the battery reports them.
estimate() {
    [ -r "$bat/energy_now" ] && [ -r "$bat/power_now" ] || return 0
    awk -v now="$(cat "$bat/energy_now")" -v full="$(cat "$bat/energy_full" 2>/dev/null || echo 0)" \
        -v power="$(cat "$bat/power_now")" -v status="$status" '
        BEGIN {
            if (power <= 0) exit
            h = (status == "Charging") ? (full - now) / power : now / power
            printf "%d:%02d %s\n", int(h), int((h - int(h)) * 60), \
                (status == "Charging") ? "until full" : "remaining"
        }'
}

case $BLOCK_BUTTON in
    1) notify-send "🔋 Battery" "$status, $cap%
$(estimate)" ;;
    3) notify-send "🔋 Battery" "⚡ charging, 🔋 on battery, 🪫 below 20%.
Critical alert once below 10%.
Left click: status and time estimate" ;;
esac

case $status in
    Discharging)
        if [ "$cap" -lt 10 ] && [ ! -e "$flag" ]; then
            notify-send -u critical "🪫 Battery critical" "$cap% left — plug in now"
            : > "$flag"
        fi
        icon="🔋"
        [ "$cap" -lt 20 ] && icon="🪫"
        ;;
    Charging) rm -f "$flag"; icon="⚡" ;;
    *)
        rm -f "$flag"
        # Full, or held at a charge threshold: hide only when actually full.
        [ "$cap" -ge 95 ] && exit 0
        icon="🔋"
        ;;
esac
echo "$icon $cap%"
```

- [ ] **Step 5: Run tests**

Run: `bats tests/statusbar.bats`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add bin/statusbar/sb-volume bin/statusbar/sb-battery tests/statusbar.bats
git commit -m "Rework volume and battery blocks: hide when absent, warn once"
```

---

### Task 5: `sb-internet` and `sb-music`

**Files:**
- Modify: `bin/statusbar/sb-internet` (full rewrite)
- Create: `bin/statusbar/sb-music`
- Test: `tests/statusbar.bats` (append)

**Interfaces:**
- Consumes: Task 1 harness.

- [ ] **Step 1: Append failing tests**

```bash
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
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/statusbar.bats --filter "internet|music"`
Expected: FAIL.

- [ ] **Step 3: Rewrite `bin/statusbar/sb-internet`**

```sh
#!/bin/sh
# Network: 📶 wifi strength, 🌐 ethernet, ❌ offline.
# Left click: nmtui. Right click: help.

case $BLOCK_BUTTON in
    1) setsid -f "${TERMINAL:-st}" -e nmtui ;;
    3) notify-send "🌐 Network" "📶 wifi with link quality
🌐 ethernet
❌ offline
Left click: manage connections (nmtui)" ;;
esac

sys="${SB_SYSFS:-/sys}/class/net"
proc="${SB_PROCFS:-/proc}"

for iface in "$sys"/w*; do
    [ "$(cat "$iface/operstate" 2>/dev/null)" = up ] || continue
    name=${iface##*/}
    # Link quality is out of 70 on most drivers.
    pct=$(awk -v n="$name:" '$1 == n { printf "%d", $3 * 100 / 70 }' "$proc/net/wireless" 2>/dev/null)
    echo "📶${pct:+ $pct%}"
    exit 0
done

for iface in "$sys"/e*; do
    [ "$(cat "$iface/operstate" 2>/dev/null)" = up ] && { echo "🌐"; exit 0; }
done

echo "❌"
```

- [ ] **Step 4: Create `bin/statusbar/sb-music`**

```sh
#!/bin/sh
# Now playing; hidden with no player. Left click: play/pause.
# Scroll up: next, down: previous. Right click: help.

case $BLOCK_BUTTON in
    1) playerctl play-pause ;;
    3) notify-send "🎵 Music" "Left click: play / pause
Scroll up: next track
Scroll down: previous track" ;;
    4) playerctl next ;;
    5) playerctl previous ;;
esac

status=$(playerctl status 2>/dev/null) || exit 0
case $status in
    Playing) icon="▶" ;;
    Paused) icon="⏸" ;;
    *) exit 0 ;;
esac

text=$(playerctl metadata --format '{{artist}} – {{title}}' 2>/dev/null)
[ -n "$text" ] || exit 0

# Count characters, not bytes, even when dwmblocks runs under the C locale.
text=$(printf '%s' "$text" | LC_ALL=C.UTF-8 sed 's/^\(.\{29\}\).\{2,\}$/\1…/')
echo "$icon $text"
```

Run: `chmod +x bin/statusbar/sb-music`

Note: the `stub` for playerctl logs `playerctl status`, etc. The `metadata` case matches because `$1` is `metadata`.

- [ ] **Step 5: Run tests (needs `iconv` in BASE_TOOLS if missing)**

If the UTF-8 test fails with `iconv: command not found`, add `iconv` to `BASE_TOOLS` in `tests/helpers/statusbar.bash` — it is only used by the test itself, which runs with the normal PATH, so this should not be needed.

Run: `bats tests/statusbar.bats`
Expected: all PASS.

- [ ] **Step 6: Lint and commit**

Run: `make lint`
Expected: clean.

```bash
git add bin/statusbar/sb-internet bin/statusbar/sb-music tests/statusbar.bats
git commit -m "Rework network block; add music block"
```

---

### Task 6: Lock, sleep wrapper, idle dim

**Files:**
- Create: `bin/lock`, `bin/lock-sleep-wrapper`, `bin/dim-screen`
- Create: `tests/lock.bats`
- Modify: `config/shell/aliases.sh:23` (`alias l='lock'`)

**Interfaces:**
- Consumes: `setup_statusbar`, `stub`, `assert_called`, `assert_not_called` (Task 1).
- Produces: `lock` (no args, blocks until unlocked); `lock-sleep-wrapper CMD...`; `dim-screen` (runs until TERM). Used by Task 9 (`.xinitrc`) and Task 10 (dwm key).

- [ ] **Step 1: Write failing tests**

`tests/lock.bats`:

```bash
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
    stub brightnessctl 'case "$1" in get) echo 500 ;; esac'

    env PATH="$STUBS:$BASE_BIN" "$REPO_ROOT/bin/dim-screen" &
    local pid=$!
    sleep 0.5
    kill -TERM "$pid"
    wait "$pid" || true

    assert_called "brightnessctl -q set 10%"
    assert_called "brightnessctl -q set 500"
}

@test "dim-screen is a no-op without a backlight" {
    stub brightnessctl
    run_bin dim-screen
    [ "$status" -eq 0 ]
    assert_not_called brightnessctl
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/lock.bats`
Expected: FAIL (scripts missing).

- [ ] **Step 3: Create `bin/lock`**

```sh
#!/bin/sh
# Lock the screen: i3lock-color over the blurred wallpaper (rendered by
# wallpaper-shuffle.sh), falling back to xtrlock. Blocks until unlocked, so
# xss-lock can track it. Cosmetic pieces missing never prevent locking.

img="${XDG_CACHE_HOME:-$HOME/.cache}/lock.png"

# i3lock-color installs as `i3lock`; its version string carries a ".c." suffix.
if command -v i3lock >/dev/null 2>&1 && i3lock --version 2>&1 | grep -q '[0-9]\.c\.'; then
    if [ -r "$img" ]; then bg="-i $img"; else bg="-c 282828"; fi

    font="FiraCode Nerd Font"
    # shellcheck disable=SC2086  # $bg is two words by design
    exec i3lock --nofork $bg \
        --ignore-empty-password --show-failed-attempts \
        --clock --indicator \
        --time-str="%H:%M" --date-str="%A, %d %B" \
        --time-font="$font" --date-font="$font" \
        --verif-font="$font" --wrong-font="$font" --layout-font="$font" \
        --time-size=72 --date-size=20 \
        --time-color=ebdbb2ff --date-color=ebdbb2ff \
        --verif-color=ebdbb2ff --wrong-color=ebdbb2ff \
        --verif-text="checking…" --wrong-text="denied" --noinput-text="empty" \
        --radius=110 --ring-width=8 \
        --inside-color=28282888 --ring-color=d79921ff \
        --insidever-color=28282888 --ringver-color=458588ff \
        --insidewrong-color=28282888 --ringwrong-color=cc241dff \
        --keyhl-color=98971aff --bshl-color=cc241dff \
        --line-uses-inside --separator-color=00000000
fi

if command -v xtrlock >/dev/null 2>&1; then
    exec xtrlock -b
fi

notify-send -u critical "🔒 Lock failed" "Neither i3lock-color nor xtrlock is installed"
exit 1
```

- [ ] **Step 4: Create `bin/lock-sleep-wrapper`**

```bash
#!/usr/bin/env bash
# Run a screen locker from xss-lock without racing suspend.
#
# xss-lock passes a sleep-inhibitor fd in XSS_SLEEP_LOCK_FD when locking
# before suspend; suspend proceeds once every copy is closed. Lockers that
# never close it (xtrlock, i3lock --nofork) would hold suspend until unlock,
# and closing it immediately lets the screen show for a moment on resume.
# Start the locker without the fd, give it time to grab the display, then
# release. Based on xss-lock's transfer-sleep-lock-generic-delay.sh.

sleep_delay=0.5

trap 'kill %% 2>/dev/null' TERM INT

if [[ -e /dev/fd/${XSS_SLEEP_LOCK_FD:--1} ]]; then
    "$@" {XSS_SLEEP_LOCK_FD}<&- &
    sleep "$sleep_delay"
    exec {XSS_SLEEP_LOCK_FD}<&-
else
    "$@" &
fi

wait
```

- [ ] **Step 5: Create `bin/dim-screen`**

```sh
#!/bin/sh
# xss-lock notifier: dim the backlight before locking; xss-lock kills this on
# activity (or when it locks), and the trap restores the previous level.

set -- "${SB_SYSFS:-/sys}"/class/backlight/*
[ -r "$1/brightness" ] || exit 0

saved=$(brightnessctl get) || exit 0
trap 'brightnessctl -q set "$saved"; exit 0' TERM INT HUP

brightnessctl -q set 10%
# Short sleeps so the trap runs promptly.
while :; do sleep 1; done
```

Run: `chmod +x bin/lock bin/lock-sleep-wrapper bin/dim-screen`

- [ ] **Step 6: Point the `l` alias at `lock`**

In `config/shell/aliases.sh`, replace `alias l='xtrlock -b'` with:

```sh
alias l='lock'                      # Lock screen (i3lock-color, falls back to xtrlock)
```

- [ ] **Step 7: Run tests and lint**

Run: `bats tests/lock.bats && make lint`
Expected: all PASS, lint clean.

- [ ] **Step 8: Commit**

```bash
git add bin/lock bin/lock-sleep-wrapper bin/dim-screen tests/lock.bats config/shell/aliases.sh
git commit -m "Add lock screen, suspend-safe lock wrapper and idle dim"
```

---

### Task 7: Wallpaper shuffle rework

**Files:**
- Modify: `bin/wallpaper-shuffle.sh` (full rewrite)
- Create: `tests/wallpaper.bats`

**Interfaces:**
- Consumes: Task 1 harness.
- Produces: `$XDG_STATE_HOME/dotfiles/wallpaper` (path of current wallpaper); `$XDG_CACHE_HOME/lock.png` (consumed by `bin/lock`, Task 6). Env overrides: `WALLPAPER_DIRS` (colon-separated), `SCREEN_SIZE` (e.g. `1920x1080`).

- [ ] **Step 1: Write failing tests**

`tests/wallpaper.bats`:

```bash
#!/usr/bin/env bats
#
# bin/wallpaper-shuffle.sh: picks from both sources, never writes into them,
# records state and renders the lock image.

load helpers/statusbar

setup() {
    setup_statusbar
    export XDG_CACHE_HOME="$TEST_HOME/.cache" XDG_STATE_HOME="$TEST_HOME/.local/state"
    OWN="$TEST_HOME/own"; EXTRA="$TEST_HOME/extra/wallpapers/minimalistic"
    mkdir -p "$OWN" "$EXTRA"
    export WALLPAPER_DIRS="$OWN:$TEST_HOME/extra"
    stub feh
    # Every file is an image unless its name contains "bad".
    stub file 'case "$*" in *bad*) echo text/plain ;; *) echo image/jpeg ;; esac'
    # magick writes its last argument, like the real thing.
    stub magick 'for a; do out=$a; done; : > "$out"'
}
teardown() { teardown_sandbox; }

run_shuffle() { run env PATH="$STUBS:$BASE_BIN" SCREEN_SIZE=1920x1080 "$@" bash "$REPO_ROOT/bin/wallpaper-shuffle.sh"; }

@test "sets a wallpaper and records it" {
    echo x > "$OWN/one.jpg"
    run_shuffle
    [ "$status" -eq 0 ]
    assert_called "feh --no-fehbg --bg-fill $OWN/one.jpg"
    [ "$(cat "$XDG_STATE_HOME/dotfiles/wallpaper")" = "$OWN/one.jpg" ]
}

@test "picks from the nested extra source" {
    echo x > "$EXTRA/deep.png"
    run_shuffle
    assert_called "$EXTRA/deep.png"
}

@test "never writes into the wallpaper folders" {
    echo x > "$OWN/one.jpg"
    local before; before=$(ls -A "$OWN")
    run_shuffle
    [ "$(ls -A "$OWN")" = "$before" ]
}

@test "handles filenames with spaces" {
    echo x > "$OWN/my wall.jpg"
    run_shuffle
    [ "$(cat "$XDG_STATE_HOME/dotfiles/wallpaper")" = "$OWN/my wall.jpg" ]
}

@test "skips invalid images" {
    echo x > "$OWN/bad.jpg"
    echo x > "$OWN/good.jpg"
    run_shuffle
    [ "$(cat "$XDG_STATE_HOME/dotfiles/wallpaper")" = "$OWN/good.jpg" ]
}

@test "renders the lock image at screen size" {
    echo x > "$OWN/one.jpg"
    run_shuffle
    assert_called "magick"
    assert_called "1920x1080"
    [ -e "$XDG_CACHE_HOME/lock.png" ]
}

@test "skips the lock image without ImageMagick" {
    rm "$STUBS/magick"
    echo x > "$OWN/one.jpg"
    run_shuffle
    [ "$status" -eq 0 ]
    [ ! -e "$XDG_CACHE_HOME/lock.png" ]
}

@test "fails cleanly with no images" {
    run_shuffle
    [ "$status" -ne 0 ]
    assert_not_called feh
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/wallpaper.bats`
Expected: FAIL (old script uses `--bg-scale`, a single PNG-only folder, and copies into it).

- [ ] **Step 3: Rewrite `bin/wallpaper-shuffle.sh`**

```bash
#!/usr/bin/env bash
#
# Wallpaper shuffle — pick a random image from the wallpaper sources, set it
# with feh, record the choice, and render the blurred lock-screen image.
#
# Sources (WALLPAPER_DIRS, colon-separated) default to the user's own folder
# and the optional gruvbox set fetched by `install.sh --wallpapers`. The
# folders are only read, never written.

set -euo pipefail

DEFAULT_DIRS="$HOME/.config/wallpapers:${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/gruvbox"
IFS=: read -r -a SOURCES <<< "${WALLPAPER_DIRS:-$DEFAULT_DIRS}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOCK_IMAGE="${XDG_CACHE_HOME:-$HOME/.cache}/lock.png"
LOG_FILE="${STATE_DIR}/wallpaper-shuffle.log"

# Log beside other dotfiles state rather than next to the script: this file is
# symlinked from ~/.local/bin, so `dirname "$0"` resolves back into the repo.
mkdir -p "$STATE_DIR"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

log() { printf '%s wallpaper-shuffle: %s\n' "$(date +%H:%M:%S)" "$1"; }

command -v feh >/dev/null 2>&1 || { log "feh not installed, aborting"; exit 1; }

# Every regular file in every existing source, skipping git metadata.
candidates=()
for dir in "${SOURCES[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' f; do
        candidates+=("$f")
    done < <(find "$dir" -type f -not -path '*/.git/*' -print0)
done

if [[ ${#candidates[@]} -eq 0 ]]; then
    log "no files found in: ${SOURCES[*]}"
    exit 1
fi

# Random order, first real image wins; bounded by the candidate count.
selected=""
while IFS= read -r -d '' candidate; do
    if [[ -s "$candidate" ]] && file --mime-type -b "$candidate" | grep -q '^image/'; then
        selected="$candidate"
        break
    fi
    log "skipping invalid or empty image: $candidate"
done < <(printf '%s\0' "${candidates[@]}" | shuf -z)

if [[ -z "$selected" ]]; then
    log "no valid images found"
    exit 1
fi

log "setting wallpaper: $selected"
feh --no-fehbg --bg-fill "$selected"
printf '%s\n' "$selected" > "$STATE_DIR/wallpaper"

# Pre-render the lock image so locking is instant. Cosmetic: skipped quietly.
if command -v magick >/dev/null 2>&1; then
    size="${SCREEN_SIZE:-}"
    if [[ -z "$size" ]] && command -v xrandr >/dev/null 2>&1; then
        size=$(xrandr 2>/dev/null | awk '/\*/ { print $1; exit }')
    fi
    size="${size:-1920x1080}"
    mkdir -p "$(dirname "$LOCK_IMAGE")"
    tmp="${LOCK_IMAGE%.png}.tmp.png"
    if magick "${selected}[0]" -resize "${size}^" -gravity center -extent "$size" \
            -blur 0x10 -fill black -colorize 35% "$tmp"; then
        mv -f "$tmp" "$LOCK_IMAGE"
        log "rendered lock image ($size)"
    else
        rm -f "$tmp"
        log "lock image render failed; lock will use a solid colour"
    fi
fi
```

- [ ] **Step 4: Run tests and lint**

Run: `bats tests/wallpaper.bats && make lint`
Expected: all PASS, clean.

- [ ] **Step 5: Commit**

```bash
git add bin/wallpaper-shuffle.sh tests/wallpaper.bats
git commit -m "Rework wallpaper shuffle: two sources, state file, lock image"
```

---

### Task 8: Installer — dunst config, packages, AUR, `--wallpapers`

**Files:**
- Create: `config/dunst/dunstrc`
- Create: `lib/wallpapers.sh`
- Create: `tests/desktop.bats`
- Modify: `lib/dotfiles.sh` (GUI map gains `config/dunst`)
- Modify: `lib/packages.sh` (new names, `AUR_PACKAGES`, `install_aur_packages`)
- Modify: `install.sh:45` (module list gains `wallpapers`) and the action `case` (gains `--wallpapers`)
- Modify: `lib/ui.sh` (usage line)

**Interfaces:**
- Produces: `fetch_wallpapers` (returns 0 on success/skip, 1 on failure); `install_aur_packages`; readonly `AUR_PACKAGES=(i3lock-color)`; `WALLPAPER_REPO` (env override `DOTFILES_WALLPAPER_REPO`), `WALLPAPER_CATEGORIES=(minimalistic)`.

- [ ] **Step 1: Write failing tests**

`tests/desktop.bats`:

```bash
#!/usr/bin/env bats
#
# Desktop pieces of the installer: dunst link, packages, AUR, wallpapers.

load helpers/common

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

@test "dotfiles links the dunst config" {
    run_install --dotfiles
    assert_success
    assert_symlink "$TEST_HOME/.config/dunst"
}

@test "minimal mode skips the dunst config" {
    run_install --minimal --dotfiles
    assert_not_exists "$TEST_HOME/.config/dunst"
}

@test "package list includes the desktop tools" {
    run_install --dry-run --packages
    assert_output_contains "dunst"
    assert_output_contains "xss-lock"
    assert_output_contains "playerctl"
}

@test "AUR step lists i3lock-color when yay exists (dry-run)" {
    mkdir -p "$TEST_HOME/stubs"
    printf '#!/bin/sh\n' > "$TEST_HOME/stubs/yay"; chmod +x "$TEST_HOME/stubs/yay"
    run env PATH="$TEST_HOME/stubs:$PATH" bash -c "
        source '$REPO_ROOT/lib/core.sh'; source '$REPO_ROOT/lib/packages.sh'
        PACKAGE_MANAGER=pacman DRY_RUN=true install_aur_packages"
    assert_success
    assert_output_contains "i3lock-color"
}

@test "AUR step warns without yay" {
    run env PATH=/usr/bin:/bin bash -c "
        command -v yay >/dev/null && exit 99
        source '$REPO_ROOT/lib/core.sh'; source '$REPO_ROOT/lib/packages.sh'
        PACKAGE_MANAGER=pacman install_aur_packages"
    [ "$status" -eq 99 ] && skip "yay installed system-wide"
    assert_success
    assert_output_contains "xtrlock"
}

@test "--wallpapers dry-run leaves no trace" {
    run_install --dry-run --wallpapers
    assert_success
    assert_not_exists "$TEST_HOME/.local/share/wallpapers"
}

@test "--wallpapers fetches only the chosen category" {
    local src="$TEST_HOME/src-repo"
    git init -q "$src"
    mkdir -p "$src/wallpapers/minimalistic" "$src/wallpapers/photography"
    echo a > "$src/wallpapers/minimalistic/a.jpg"
    echo b > "$src/wallpapers/photography/b.jpg"
    git -C "$src" add . && git -C "$src" -c user.name=t -c user.email=t@t commit -qm init

    DOTFILES_WALLPAPER_REPO="file://$src" run_install --wallpapers
    assert_success
    [ -f "$TEST_HOME/.local/share/wallpapers/gruvbox/wallpapers/minimalistic/a.jpg" ]
    assert_not_exists "$TEST_HOME/.local/share/wallpapers/gruvbox/wallpapers/photography/b.jpg"
}

@test "--wallpapers is listed in --help" {
    run_install --help
    assert_output_contains "--wallpapers"
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/desktop.bats`
Expected: FAIL.

- [ ] **Step 3: Create `config/dunst/dunstrc`**

```ini
# dunst — gruvbox dark, matching dwm/dmenu/st. Reload: killall dunst.

[global]
    monitor = 0
    follow = keyboard
    origin = top-right
    offset = (12, 36)
    width = 350
    notification_limit = 5
    font = FiraCode Nerd Font 10
    frame_width = 2
    corner_radius = 0
    separator_height = 2
    separator_color = frame
    padding = 10
    horizontal_padding = 12
    gap_size = 6
    icon_position = left
    max_icon_size = 32
    format = "<b>%s</b>\n%b"
    alignment = left
    word_wrap = yes
    show_age_threshold = 60
    history_length = 30
    mouse_left_click = close_current
    mouse_middle_click = do_action, close_current
    mouse_right_click = close_all

[urgency_low]
    background = "#282828"
    foreground = "#a89984"
    frame_color = "#504945"
    timeout = 3

[urgency_normal]
    background = "#282828"
    foreground = "#ebdbb2"
    frame_color = "#d79921"
    timeout = 5

[urgency_critical]
    background = "#cc241d"
    foreground = "#ebdbb2"
    frame_color = "#fb4934"
    timeout = 0
```

- [ ] **Step 4: Add dunst to the symlink map**

In `lib/dotfiles.sh`, in the GUI `dotfiles+=(...)` block, after the `config/cmus` line, add:

```bash
            "$DOTFILES_DIR/config/dunst:$HOME/.config/dunst"
```

- [ ] **Step 5: Packages and AUR step in `lib/packages.sh`**

After `readonly -a COMMON_PACKAGES=(...)`, add:

```bash
# AUR-only desktop packages (pacman systems with yay).
readonly -a AUR_PACKAGES=(i3lock-color)
```

Change the GUI lines in the `case`:

```bash
        pacman)
            ...
            is_headless || packages+=(libx11 libxft libxinerama dunst xss-lock playerctl xtrlock)
            ;;
        apt)
            ...
            is_headless || packages+=(libx11-dev libxft-dev libxinerama-dev dunst xss-lock playerctl xtrlock)
            ...
        dnf)
            ...
            is_headless || packages+=(libX11-devel libXft-devel libXinerama-devel dunst xss-lock playerctl)
            ;;
```

Replace the dry-run block and the end of `install_packages`:

```bash
    if is_dry_run; then
        print_dry "install ${#packages[@]} package(s) via ${PACKAGE_MANAGER}"
        install_aur_packages
        return 0
    fi
```

```bash
    [[ "$PACKAGE_MANAGER" == apt ]] && link_renamed_binaries
    install_aur_packages

    print_ok "Package installation completed"
}

# AUR packages via yay on pacman systems. Optional: without yay, bin/lock
# falls back to xtrlock, so this only warns.
install_aur_packages() {
    [[ "${PACKAGE_MANAGER:-}" == pacman ]] || return 0
    is_headless && return 0

    if ! command_exists yay; then
        print_warn "yay not found — skipping AUR packages (${AUR_PACKAGES[*]}); the lock screen falls back to xtrlock"
        return 0
    fi

    if is_dry_run; then
        print_dry "install AUR package(s) via yay: ${AUR_PACKAGES[*]}"
        return 0
    fi

    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" ||
        print_warn "AUR install failed (${AUR_PACKAGES[*]}); the lock screen falls back to xtrlock"
}
```

- [ ] **Step 6: Create `lib/wallpapers.sh`**

```bash
#!/usr/bin/env bash
# lib/wallpapers.sh — Optional curated wallpaper download (--wallpapers).
#
# The source repo is ~1.4 GB, so only the chosen categories are fetched with
# a shallow, blob-filtered, sparse checkout. Nothing is committed here: the
# images have no single license and stay a local download.
#
# shellcheck shell=bash

[[ -n "${DOTFILES_WALLPAPERS_SOURCED:-}" ]] && return 0
readonly DOTFILES_WALLPAPERS_SOURCED=1

readonly WALLPAPER_REPO="${DOTFILES_WALLPAPER_REPO:-https://github.com/AngelJumbo/gruvbox-wallpapers.git}"
readonly -a WALLPAPER_CATEGORIES=(minimalistic)
readonly WALLPAPER_DEST="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/gruvbox"

fetch_wallpapers() {
    print_section "Wallpapers"

    local -a paths=()
    local category
    for category in "${WALLPAPER_CATEGORIES[@]}"; do
        paths+=("wallpapers/$category")
    done

    if is_dry_run; then
        print_dry "fetch ${WALLPAPER_CATEGORIES[*]} wallpapers into $WALLPAPER_DEST"
        return 0
    fi

    confirm "Download gruvbox wallpapers (${WALLPAPER_CATEGORIES[*]}, ~58 MB) to $WALLPAPER_DEST?" y ||
        { print_status "Wallpaper download skipped"; return 0; }

    command_exists git || { print_error "git is required to fetch wallpapers"; return 1; }

    if [[ -d "$WALLPAPER_DEST/.git" ]]; then
        print_status "Updating wallpapers..."
        git -C "$WALLPAPER_DEST" sparse-checkout set "${paths[@]}" &&
            git -C "$WALLPAPER_DEST" pull -q --ff-only --depth 1 ||
            { print_error "Wallpaper update failed"; return 1; }
    else
        print_status "Fetching wallpapers..."
        mkdir -p "$(dirname "$WALLPAPER_DEST")"
        git clone -q --depth 1 --filter=blob:none --sparse "$WALLPAPER_REPO" "$WALLPAPER_DEST" &&
            git -C "$WALLPAPER_DEST" sparse-checkout set "${paths[@]}" ||
            { print_error "Wallpaper download failed"; rm -rf "$WALLPAPER_DEST"; return 1; }
    fi

    local count
    count=$(find "$WALLPAPER_DEST/wallpapers" -type f 2>/dev/null | wc -l)
    print_ok "Wallpapers ready: ${count} image(s) in $WALLPAPER_DEST"
    print_status "Shuffle with Super+w or wallpaper-shuffle.sh"
}
```

- [ ] **Step 7: Wire the flag**

`install.sh` module loop: change to

```bash
for _module in profiles location symlinks system packages dotfiles suckless server update wallpapers ui; do
```

In the action `case` of `parse_args`, next to `--show-log`, add:

```bash
            --wallpapers)
                if is_headless; then
                    print_warn "Skipping wallpapers in server/minimal mode"
                else
                    fetch_wallpapers || true
                fi
                ran_command=true
                shift
                ;;
```

`lib/ui.sh` usage, after the `--show-log` line, add:

```
      --wallpapers       Download the curated gruvbox wallpaper set (~58 MB)
```

- [ ] **Step 8: Run tests, full suite and dry-run**

Run: `bats tests/desktop.bats && make check`
Expected: all PASS; `dry-run: clean`.

- [ ] **Step 9: Commit**

```bash
git add config/dunst lib/wallpapers.sh lib/dotfiles.sh lib/packages.sh lib/ui.sh install.sh tests/desktop.bats
git commit -m "Installer: dunst config, desktop packages, AUR step, --wallpapers"
```

---

### Task 9: Session start (`.xinitrc`)

**Files:**
- Modify: `.xinitrc` (section after `xinitrc.d` loop)
- Test: `tests/desktop.bats` (append)

**Interfaces:**
- Consumes: `lock`, `lock-sleep-wrapper`, `dim-screen` (Task 6), `wallpaper-shuffle.sh` (Task 7), dunst config (Task 8).

- [ ] **Step 1: Append failing test**

```bash
@test "xinitrc starts the session in order" {
    # Line number of the first line starting with the given text.
    line() { grep -n -m1 -- "^$1" "$REPO_ROOT/.xinitrc" | cut -d: -f1; }
    local prev=0 n step
    for step in "\[ -f \"\$HOME/.config/shell/envars.sh\" \]" "setxkbmap" "xset s" "picom" \
                "dunst" "xss-lock" "redshift" "~/.local/bin/wallpaper-shuffle" \
                "dwmblocks" "~/.local/bin/fix-audio" "exec dwm"; do
        n=$(line "$step")
        [ -n "$n" ] || { echo "missing: $step"; return 1; }
        [ "$n" -gt "$prev" ] || { echo "out of order: $step"; return 1; }
        prev=$n
    done
    grep -q 'xss-lock .*-n dim-screen .*-- lock-sleep-wrapper lock' "$REPO_ROOT/.xinitrc"
    grep -q 'xset s 570 30' "$REPO_ROOT/.xinitrc"
    grep -q 'xset dpms 0 0 900' "$REPO_ROOT/.xinitrc"
}
```

- [ ] **Step 2: Run to verify failure**

Run: `bats tests/desktop.bats --filter xinitrc`
Expected: FAIL.

- [ ] **Step 3: Replace everything after the `xinitrc.d` loop in `.xinitrc`**

```sh
# Environment for everything started below — dwmblocks click handlers need
# $TERMINAL/$EDITOR and PATH even when X is launched by a display manager.
# shellcheck source=config/shell/envars.sh
[ -f "$HOME/.config/shell/envars.sh" ] && . "$HOME/.config/shell/envars.sh"

# Keyboard Layout
setxkbmap uk &

# Display Resolution — VM display only; set it before the wallpaper so feh
# scales to the final size.
if xrandr 2>/dev/null | grep -q '^Virtual-1 connected'; then
    xrandr --output Virtual-1 --mode 1920x1080
fi

# Idle: screensaver event at 9:30 (dim), lock 30s later; display off at 15 min.
xset s 570 30
xset dpms 0 0 900

# compositor
picom -f &

# notifications
dunst &

# Lock on idle and before suspend, dimming first.
xss-lock --transfer-sleep-lock -n dim-screen -- lock-sleep-wrapper lock &

# redshift
redshift -l -6:34 -t 5500:2500 &

# Wallpaper (also renders the lock-screen image)
~/.local/bin/wallpaper-shuffle.sh &

dwmblocks &

# Audio routing
~/.local/bin/fix-audio.sh &

exec dwm
```

- [ ] **Step 4: Run test and lint**

Run: `bats tests/desktop.bats && make lint`
Expected: PASS, clean.

- [ ] **Step 5: Commit**

```bash
git add .xinitrc tests/desktop.bats
git commit -m "Start dunst and xss-lock auto-lock from .xinitrc"
```

---

### Task 10: dwm — patches and `config.h`

**Files (in submodule `suckless/dwm`):**
- Create: `patches/dwm-statuscmd-20241009-8933ebc.diff`, `patches/dwm-restartsig-20180523-6.2.diff`
- Modify: `dwm.c`, `config.def.h`, `dwm.1` (via patches)
- Create: `config.h`
- Modify (superproject): `suckless/dwm` pointer

**Interfaces:**
- Consumes: block signals (Global Constraints), `lock`, `wallpaper-shuffle.sh`.
- Produces: `STATUSBAR "dwmblocks"` for statuscmd; buttons 1–5 sent to the bar.

- [ ] **Step 1: Apply the patches (statuscmd first, restartsig with fuzz)**

```bash
cd suckless/dwm
mkdir -p patches
curl -fsSL -o patches/dwm-statuscmd-20241009-8933ebc.diff \
    https://dwm.suckless.org/patches/statuscmd/dwm-statuscmd-20241009-8933ebc.diff
curl -fsSL -o patches/dwm-restartsig-20180523-6.2.diff \
    https://dwm.suckless.org/patches/restartsig/dwm-restartsig-20180523-6.2.diff
git apply patches/dwm-statuscmd-20241009-8933ebc.diff
patch -p1 -F3 < patches/dwm-restartsig-20180523-6.2.diff
rm -f ./*.orig ./*.rej
```

Expected: restartsig reports `Hunk #1 succeeded at 205 with fuzz 3` and other hunks succeed with offsets; no `.rej` files.

- [ ] **Step 2: Verify restartsig hunks landed in the right functions**

Run: `git diff dwm.c | grep -E '^\+.*(sighup|sigterm|restart|execvp)'`
Expected exactly these additions: prototypes `static void sighup(int unused);` and `static void sigterm(int unused);`, `static int restart = 0;`, `if(arg->i) restart = 1;` inside `quit()`, `signal(SIGHUP, sighup);` and `signal(SIGTERM, sigterm);` in `setup()`, the `sighup`/`sigterm` definitions, and `if(restart) execvp(argv[0], argv);` in `main()`.

- [ ] **Step 3: Write `config.h`**

```c
/* See LICENSE file for copyright and license details. */
/* Personal config: Super mod key, gruvbox dark, FiraCode. config.def.h stays upstream. */

#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "FiraCode Nerd Font:size=10" };
static const char dmenufont[]       = "FiraCode Nerd Font:size=10";
static const char col_bg[]          = "#282828";
static const char col_bg1[]         = "#3c3836";
static const char col_fg[]          = "#ebdbb2";
static const char col_yellow[]      = "#d79921";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_fg,    col_bg,    col_bg1  },
	[SchemeSel]  = { col_bg,    col_yellow, col_yellow },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   monitor */
	/* Placeholder that never matches; add per-app rules here. */
	{ "dwm-no-rules", NULL,   NULL,       0,            0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* statuscmd: clicks on the status text are forwarded to this process */
#define STATUSBAR "dwmblocks"

/* Run CMD, then refresh dwmblocks-async block SIG (real-time signal 34+SIG).
 * `;` not `&&`: the action must happen even if the bar is not running. */
#define BARCMD(cmd, sig) SHCMD(cmd "; kill -$((34+" #sig ")) $(pidof dwmblocks) 2>/dev/null")

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_bg, "-nf", col_fg, "-sb", col_yellow, "-sf", col_bg, NULL };
static const char *termcmd[]  = { "st", NULL };
static const char *lockcmd[]  = { "lock", NULL };
static const char *wallcmd[]  = { "wallpaper-shuffle.sh", NULL };

static const Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_d,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_o,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY,                       XK_q,      killclient,     {0} },
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	{ MODKEY,                       XK_w,      spawn,          {.v = wallcmd } },
	{ MODKEY,                       XK_n,      spawn,          SHCMD("dunstctl close") },
	{ MODKEY|ShiftMask,             XK_n,      spawn,          SHCMD("dunstctl history-pop") },
	{ MODKEY|ShiftMask,             XK_l,      spawn,          {.v = lockcmd } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_r,      quit,           {1} }, /* restart in place (restartsig) */
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },

	/* hardware keys; each refreshes its bar block */
	{ 0, XF86XK_AudioRaiseVolume,  spawn, BARCMD("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+", 7) },
	{ 0, XF86XK_AudioLowerVolume,  spawn, BARCMD("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", 7) },
	{ 0, XF86XK_AudioMute,         spawn, BARCMD("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", 7) },
	{ 0, XF86XK_MonBrightnessUp,   spawn, BARCMD("brightnessctl -q set 5%+", 8) },
	{ 0, XF86XK_MonBrightnessDown, spawn, BARCMD("brightnessctl -q set 5%-", 8) },
	{ 0, XF86XK_AudioPlay,         spawn, BARCMD("playerctl play-pause", 1) },
	{ 0, XF86XK_AudioNext,         spawn, BARCMD("playerctl next", 1) },
	{ 0, XF86XK_AudioPrev,         spawn, BARCMD("playerctl previous", 1) },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button1,        sigstatusbar,   {.i = 1} },
	{ ClkStatusText,        0,              Button2,        sigstatusbar,   {.i = 2} },
	{ ClkStatusText,        0,              Button3,        sigstatusbar,   {.i = 3} },
	{ ClkStatusText,        0,              Button4,        sigstatusbar,   {.i = 4} },
	{ ClkStatusText,        0,              Button5,        sigstatusbar,   {.i = 5} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
```

- [ ] **Step 4: Build**

Run: `cd suckless/dwm && make clean && make 2>&1 | grep -iE "error|warning" ; ls -la dwm`
Expected: no errors; `dwm` binary exists. (Upstream warnings about `signal()` from restartsig are acceptable; errors are not.)

- [ ] **Step 5: Verify the BARCMD expansion**

Run: `cd suckless/dwm && strings dwm | grep 'kill -\$((34+'`
Expected: 8 lines, e.g. `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; kill -$((34+7)) $(pidof dwmblocks) 2>/dev/null`.

- [ ] **Step 6: Commit in the fork, then the pointer**

```bash
cd suckless/dwm
git add patches config.h config.def.h dwm.c dwm.1
git commit -m "Add statuscmd and restartsig; personal config.h (Super, gruvbox, bar keys)"
cd ../..
git add suckless/dwm
git commit -m "Bump dwm: statuscmd, restartsig, personal config"
```

---

### Task 11: dmenu and st `config.h`

**Files (submodules):**
- Create: `suckless/dmenu/config.h`, `suckless/st/config.h`
- Modify (superproject): pointers

- [ ] **Step 1: dmenu `config.h`**

```bash
cd suckless/dmenu
cp config.def.h config.h
```

Then in `config.h` replace everything from the line `static const char *fonts[] = {` through the closing `};` of `colors[SchemeLast][2]` (this range includes the `prompt` line) with:

```c
static const char *fonts[] = {
	"FiraCode Nerd Font:size=10"
};
static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
static const char *colors[SchemeLast][2] = {
	/*     fg         bg       */
	[SchemeNorm] = { "#ebdbb2", "#282828" },
	[SchemeSel] = { "#282828", "#d79921" },
	[SchemeOut] = { "#282828", "#689d6a" },
};
```

Run: `make clean && make && ls -la dmenu`
Expected: builds.

- [ ] **Step 2: st `config.h`**

```bash
cd ../st
cp config.def.h config.h
sed -i 's|^static char \*font = .*|static char *font = "FiraCode Nerd Font Mono:pixelsize=14:antialias=true:autohint=true";|' config.h
grep -n '^static char \*font' config.h
make clean && make && ls -la st
```

Expected: font line shows FiraCode; builds.

- [ ] **Step 3: Verify only intended differences**

Run: `diff suckless/dmenu/config.def.h suckless/dmenu/config.h; diff suckless/st/config.def.h suckless/st/config.h`
Expected: dmenu shows only fonts/colors; st shows only the font line.

- [ ] **Step 4: Commit forks and pointers**

```bash
(cd suckless/dmenu && git add config.h && git commit -m "Personal config.h: gruvbox, FiraCode")
(cd suckless/st && git add config.h && git commit -m "Personal config.h: FiraCode Nerd Font Mono")
git add suckless/dmenu suckless/st
git commit -m "Bump dmenu and st: gruvbox and FiraCode configs"
```

Note: if `config.h` is listed in a fork's `.gitignore`, use `git add -f config.h`.

---

### Task 12: Switch dwmblocks to dwmblocks-async

**Files:**
- Modify: `.gitmodules` (dwmblocks URL)
- Submodule `suckless/dwmblocks`: new branch from upstream dwmblocks-async; `config.h`
- Modify (superproject): pointer

**Prerequisite:** the user has forked `UtkarshVerma/dwmblocks-async` to `TheCollinsByte/dwmblocks-async`. If not yet, do Steps 1–4 and stop before Step 5.

- [ ] **Step 1: Bring in dwmblocks-async**

```bash
cd suckless/dwmblocks
git remote add async https://github.com/UtkarshVerma/dwmblocks-async.git
git fetch -q async main
git checkout -b async async/main
```

- [ ] **Step 2: Write `config.h`**

```c
#ifndef CONFIG_H
#define CONFIG_H

// String used to delimit block outputs in the status.
#define DELIMITER " │ "

// Maximum number of Unicode characters that a block can output.
#define MAX_BLOCK_OUTPUT_LENGTH 45

// Control whether blocks are clickable (needs dwm's statuscmd patch).
#define CLICKABLE_BLOCKS 1

// Control whether a leading delimiter should be prepended to the status.
#define LEADING_DELIMITER 0

// Control whether a trailing delimiter should be appended to the status.
#define TRAILING_DELIMITER 0

// X(icon, command, interval in seconds, signal). Every signal is unique and
// non-zero: signal 0 makes a block unclickable. dwm's hardware keys refresh
// a block with `kill -$((34+signal)) $(pidof dwmblocks)`.
#define BLOCKS(X)                  \
    X("", "sb-music",        5,  1) \
    X("", "sb-internet",    10,  2) \
    X("", "sb-cpu",          5,  3) \
    X("", "sb-memory",      10,  4) \
    X("", "sb-disk",       120,  5) \
    X("", "sb-kbd",          0,  6) \
    X("", "sb-volume",      60,  7) \
    X("", "sb-brightness",  60,  8) \
    X("", "sb-battery",     30,  9) \
    X("", "sb-clock",       30, 10)

#endif  // CONFIG_H
```

- [ ] **Step 3: Build**

Run: `make clean && make && ls -la build/dwmblocks`
Expected: builds.

- [ ] **Step 4: Commit locally**

```bash
git add config.h
git commit -m "Personal config.h: ten clickable, signalled blocks"
```

- [ ] **Step 5: Point the submodule at the fork**

```bash
git remote add fork https://github.com/TheCollinsByte/dwmblocks-async
cd ../..
git config -f .gitmodules submodule.suckless/dwmblocks.url https://github.com/TheCollinsByte/dwmblocks-async
git submodule sync -q suckless/dwmblocks
git add .gitmodules suckless/dwmblocks
git commit -m "Switch dwmblocks to dwmblocks-async with clickable blocks"
```

User then pushes: `cd suckless/dwmblocks && git push fork async:main` (after the fork exists).

---

### Task 13: Docs, full verification, acceptance checklist

**Files:**
- Modify: `docs/CHANGELOG.md`, `README.md`, `CLAUDE.md` (test count, submodule note), `docs/TODO.md`
- Create: `docs/DESKTOP.md` (keymap, bar, lock, manual checklist)

- [ ] **Step 1: Write `docs/DESKTOP.md`**

Contents (exactly these sections):
- **Keys** — the keymap table from spec §2 with the hardware keys.
- **Status bar** — the block table from spec §3 (output, hidden when, click/scroll).
- **Lock and idle** — `lock`, auto-lock timings, `l` alias, fallbacks.
- **Wallpapers** — sources, Super+w, `--wallpapers`.
- **Rebuilding** — `./install.sh -b`, then Super+Shift+R.
- **Acceptance checklist** — the five manual checks from spec §5, as `- [ ]` items.

- [ ] **Step 2: Changelog**

Add under `## [Unreleased]` → `### Added`:

```markdown
- **dwm desktop foundations** (see `docs/DESKTOP.md`): Super-key keymap,
  gruvbox and FiraCode across dwm/dmenu/st/dunst, statuscmd and restartsig
  patches, dwmblocks-async with ten clickable blocks that hide when
  irrelevant and refresh instantly from hardware keys, dunst notifications,
  an i3lock-color lock screen over the blurred wallpaper with xtrlock
  fallback, auto-lock (dim 9:30, lock 10:00, before suspend), and
  `--wallpapers` for an optional curated set.
```

- [ ] **Step 3: Update counts and notes**

Run: `bats tests/*.bats | tail -1` to get the new total N; replace the test count in `README.md` and `CLAUDE.md` with N. In `CLAUDE.md` § Submodules, change `suckless/{dwm,st,dmenu,dwmblocks}` text to note that `suckless/dwmblocks` is dwmblocks-async and that each fork keeps a committed `config.h`.

- [ ] **Step 4: Full verification**

Run: `make check`
Expected: lint, syntax, dry-run clean; all tests pass.

Run: `for r in dwm dmenu st dwmblocks; do (cd suckless/$r && make -s >/dev/null && echo "$r builds"); done`
Expected: four "builds" lines.

- [ ] **Step 5: Commit**

```bash
git add docs README.md CLAUDE.md
git commit -m "Document the desktop foundations"
```

- [ ] **Step 6: Hand over**

Tell the user, in this order:
1. Push each fork (`dwm`, `dmenu`, `st`, and `dwmblocks` to the new fork), then this repo.
2. `./install.sh --packages` (installs dunst, xss-lock, playerctl, xtrlock, AUR i3lock-color), then `./install.sh --dotfiles`, then `./install.sh -b` (needs sudo).
3. Optional: `./install.sh --wallpapers`.
4. Start X and run the acceptance checklist in `docs/DESKTOP.md`.
