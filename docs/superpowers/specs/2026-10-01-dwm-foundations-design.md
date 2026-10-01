# dwm Foundations — Design

**Date:** 2026-10-01
**Status:** Approved in conversation, awaiting written-spec review
**Sub-project:** 1 of 4 (Foundations → st ergonomics → dwm patches → dmenu scripts)

## Goal

Turn the stock, unconfigured dwm desktop on the daily-driver laptop into a
cohesive, keyboard-driven, gruvbox-themed environment whose status bar is
informative, clickable and instant, with notifications, a polished lock screen
and automatic locking — all reproducible from this repo.

## Current state (verified 2026-10-01)

- dwm, dmenu and st forks are upstream code with **no `config.h` committed**;
  the installed binaries (Dec 2024) were built from config nobody can recover.
- dwmblocks is stock torrinfail: signals, no click support. Its `blocks.h`
  shows only memory and date; none of the 7 `bin/statusbar/sb-*` scripts run.
- No notification daemon, so every `notify-send` is silent.
- Locking is manual only (`alias l='xtrlock -b'`).
- `sb-volume` errors when no default sink resolves; `sb-iplocate` truncates
  country names that contain a comma.
- `wallpaper-shuffle.sh` copies the chosen image over
  `~/.config/wallpapers/wallpaper.png`, duplicating one of the user's images.
- Laptop panel: eDP-1, 1920x1080. ImageMagick, feh, brightnessctl, nmcli and
  wpctl are installed. FiraCode Nerd Font is installed.

## Decisions

| Topic | Decision |
|---|---|
| Window manager | Stay on dwm (X11) |
| Mod key | Super |
| Theme | gruvbox dark everywhere, `FiraCode Nerd Font:size=10` |
| Config storage | Committed `config.h` per fork; `config.def.h` stays upstream |
| Status bar engine | dwmblocks-async (replaces the stock dwmblocks fork) |
| dwm patches in this sub-project | `statuscmd` (clickable blocks), `restartsig` (in-place restart) |
| Notifications | dunst |
| Locker | i3lock-color via `bin/lock`, fallback `xtrlock -b` |
| Auto-lock | xss-lock: dim at 9:30 idle, lock at 10:00, lock before suspend |
| Wallpapers | User folder always; optional curated gruvbox set via `--wallpapers` |

## Prerequisite (user action)

Fork `UtkarshVerma/dwmblocks-async` on GitHub as `TheCollinsByte/dwmblocks-async`.
The `suckless/dwmblocks` submodule is repointed to it. The old fork is left
untouched on GitHub.

## Palette

| Role | Hex |
|---|---|
| bg / bg1 / bg2 | `#282828` / `#3c3836` / `#504945` |
| fg | `#ebdbb2` |
| gray | `#928374` |
| red / green / yellow | `#cc241d` / `#98971a` / `#d79921` |
| blue / purple / aqua / orange | `#458588` / `#b16286` / `#689d6a` / `#d65d0e` |

## 1. Repository layout

```
suckless/dwm/config.h            Super, keys, colours, font, statuscmd/restartsig wiring
suckless/dwm/                    + statuscmd, restartsig patches (committed in fork)
suckless/dmenu/config.h          gruvbox + FiraCode
suckless/st/config.h             gruvbox (already in config.def.h via patch) + FiraCode
suckless/dwmblocks/              → dwmblocks-async fork, config.h with blocks below
bin/statusbar/sb-*               block scripts (POSIX sh)
bin/lock                         i3lock-color wrapper with fallbacks
bin/dim-screen                   idle-dim notifier for xss-lock
bin/wallpaper-shuffle.sh         + lock-image render, state file, two sources
config/dunst/dunstrc             notification theme
.xinitrc                         session start order
lib/dotfiles.sh                  + config/dunst mapping
lib/packages.sh                  + dunst xss-lock playerctl; AUR i3lock-color
lib/wallpapers.sh (new)          --wallpapers download step
```

## 2. dwm

### Keymap (❖ = Super)

| Key | Action |
|---|---|
| ❖ Enter | st |
| ❖ d | dmenu_run |
| ❖ q | kill client |
| ❖ Shift+Enter | zoom (swap with master) |
| ❖ j / k | focus stack next / previous |
| ❖ h / l | master factor −/+ 0.05 |
| ❖ i / o | inc / dec master count |
| ❖ t / f / m | tile / floating / monocle |
| ❖ Space | toggle previous layout |
| ❖ Shift+Space | toggle floating |
| ❖ b | toggle bar |
| ❖ 1–9 / ❖ Shift+1–9 | view tag / tag client |
| ❖ 0 / ❖ Shift+0 | view all / tag all |
| ❖ Tab | previous tag set |
| ❖ , / . and Shift variants | focus / tag monitor |
| ❖ w | next wallpaper (`wallpaper-shuffle.sh`) |
| ❖ n / ❖ Shift+N | dunst close / history pop |
| ❖ Shift+L | lock |
| ❖ Shift+R | restart dwm in place (restartsig) |
| ❖ Shift+Q | quit dwm |
| XF86AudioRaiseVolume / Lower / Mute | `wpctl` ±5% / toggle, signal volume block |
| XF86MonBrightnessUp / Down | `brightnessctl` ±5%, signal brightness block |
| XF86AudioPlay / Next / Prev | `playerctl`, signal music block |

Hardware-key commands run through `sh -c "… ; kill -$((34+N)) $(pidof dwmblocks)"`
so the bar updates in the same keystroke.

### Look

- `SchemeNorm`: fg `#ebdbb2`, bg `#282828`, border `#3c3836`
- `SchemeSel`: fg `#282828`, bg `#d79921`, border `#d79921`
- `borderpx = 2`, no gaps (vanitygaps belongs to the dwm-patches sub-project)
- Example rules for Gimp and Firefox removed; `rules[]` keeps one inert entry
  so the array is non-empty.

### Patches

- **statuscmd**: clicks on the status text are sent to dwmblocks-async with
  the button number; required for `$BLOCK_BUTTON`.
- **restartsig**: ❖ Shift+R re-execs dwm; open windows survive.

Both applied as commits in the dwm fork, with the patch file kept in
`patches/` for reference.

## 3. Status bar

### Conventions (all blocks)

- POSIX `sh`, one file per block in `bin/statusbar/`.
- Prints nothing when it has nothing useful to show; dwmblocks-async then
  hides the block and its delimiter.
- `BLOCK_BUTTON`: 1 = main action, 3 = help notification, 4/5 = scroll up/down.
- Help text lists exactly what the block's clicks do.
- External commands are looked up at run time; a missing tool hides the block
  rather than printing an error.
- Testable: paths under `/sys` are read via `${SB_SYSFS:-/sys}` so tests can
  point at a fixture tree.

### Blocks (left → right)

| # | Script | Output | Hidden when | Warning | Click 1 | Scroll | Interval / signal |
|---|---|---|---|---|---|---|---|
| 1 | sb-music | `▶ Artist – Title` (≤30 chars, `⏸` when paused) | no player | — | play-pause | next / previous | 5s / sig 1 |
| 2 | sb-internet | `📶 78%` wifi, `🌐` ethernet | — | `❌` offline | `nmtui` in `$TERMINAL` | — | 10s / sig 2 |
| 3 | sb-cpu | `💻 12%` | — | `🔥` ≥ 90% | `htop -s PERCENT_CPU` | — | 5s / sig 3 |
| 4 | sb-memory | `🧠 13.8/23.2G` | — | `🔥` ≥ 90% | `htop -s PERCENT_MEM` | — | 10s / sig 4 |
| 5 | sb-disk | `💾 61%` (root fs) | — | `⚠` ≥ 90% | notify `df -h` summary | — | 120s / sig 5 |
| 6 | sb-kbd | `⌨ uk` | ≤ 1 layout configured | — | cycle layout | — | 0 / sig 6 |
| 7 | sb-volume | `🔊 45%`, `🔈`/`🔉` by level, `🔇` muted | no audio server | — | toggle mute | ±5% | 60s / sig 7 |
| 8 | sb-brightness | `💡 70%` | no backlight | — | — | ±5% | 60s / sig 8 |
| 9 | sb-battery | `🔋 82%`, `⚡` charging | no battery, or full on AC | `🪫` < 20%; one critical notification < 10% per discharge | notify status + time estimate | — | 30s / sig 9 |
| 10 | sb-clock | `Thu Oct 01 10:41` | — | — | notify month `cal` | — | 30s / sig 10 |

Every block has a non-zero signal because dwmblocks-async makes signal-0
blocks unclickable. Signals are unique.

`sb-cpu` computes usage from two `/proc/stat` samples stored in
`$XDG_RUNTIME_DIR/sb-cpu` (no sleep in the block). `sb-battery` keeps its
"already warned" flag in `$XDG_RUNTIME_DIR/sb-battery-warned`, cleared when
charging resumes.

`sb-iplocate` is removed from the bar but kept on disk; its fix belongs to the
dmenu-scripts sub-project.

## 4. Notifications, locking, wallpapers, session

### dunst (`config/dunst/dunstrc`)

Top-right, width 350, max 5 visible, FiraCode 10, frame 2px, corner radius 0.
Normal: bg `#282828`, fg `#ebdbb2`, frame `#d79921`, timeout 5s.
Low: frame `#504945`, timeout 3s. Critical: bg `#cc241d`, fg `#ebdbb2`,
frame `#fb4934`, timeout 0 (stays until dismissed).

### `bin/lock`

1. If `i3lock-color` is installed: run it on `$XDG_CACHE_HOME/lock.png` when
   present, else on solid `#282828`. Clock (`%H:%M`) and date (`%A, %d %B`) in
   FiraCode, fg `#ebdbb2`. Ring: idle `#d79921`, typing `#98971a`, wrong
   `#cc241d`, verifying `#458588`. `--nofork` so xss-lock can track it.
2. Else: `xtrlock -b`.
3. Never exits early because a cosmetic piece is missing.

The `l` alias points at `lock`.

### Auto-lock

- `.xinitrc`: `xset s 570 30` (pre-lock at 9:30, lock 30s later) and
  `xset dpms 0 0 900` (display off at 15 min).
- `xss-lock -n dim-screen --transfer-sleep-lock -- <wrapper> lock`, where the
  wrapper is xss-lock's documented
  `transfer-sleep-lock-generic-delay.sh` pattern (start locker, wait 0.5s,
  release the sleep inhibitor) vendored as `bin/lock-sleep-wrapper`. This
  locks before suspend with no flash of content on resume.
- `bin/dim-screen`: saves brightness, dims to 10%, and restores on
  SIGTERM/SIGINT (xss-lock kills it on activity). No-op without a backlight.

### Wallpapers

- Sources: `~/.config/wallpapers` (always) and
  `~/.local/share/wallpapers/gruvbox` (if populated).
- `wallpaper-shuffle.sh`:
  - picks a random valid image from both sources (MIME check, any image type)
  - sets it with feh
  - records the path in `$XDG_STATE_HOME/dotfiles/wallpaper`
  - renders `$XDG_CACHE_HOME/lock.png`: screen-sized, blurred, darkened, via
    ImageMagick; skipped without `magick`
  - no longer writes into the wallpaper folder
- `./install.sh --wallpapers`: fetches from
  `https://github.com/AngelJumbo/gruvbox-wallpapers` into
  `~/.local/share/wallpapers/gruvbox`.
  - **What it fetches:** that repo is 1.4 GB, so it uses a depth-1,
    blob-filtered, sparse checkout of the categories in `WALLPAPER_CATEGORIES`
    (default: `minimalistic`, 99 images, ~58 MB). The repo URL and category
    list are readonly variables in `lib/wallpapers.sh`.
  - **How it runs:** dry-run guarded and confirm-gated. Re-running updates in
    place.
  - **Licensing:** nothing is committed or redistributed. The repo has no
    license, so images stay a local download.

### `.xinitrc` order

```
envars → xrdb → setxkbmap → xrandr (VM only) → xset s/dpms
→ picom → dunst → xss-lock → redshift → wallpaper-shuffle → dwmblocks
→ fix-audio → exec dwm
```

## 5. Installation and testing

### Installer

- `lib/packages.sh` (pacman): add `dunst xss-lock playerctl`. Other managers
  get their equivalents where they exist.
- AUR: `i3lock-color` installed with `yay -S --needed` when `yay` exists and
  not headless; otherwise a warning that `bin/lock` will fall back to xtrlock.
- `lib/dotfiles.sh`: add `config/dunst:$HOME/.config/dunst`.
- `--wallpapers` flag as above; listed in `--help` and the menu.
- All new mutations follow the three invariants (dry-run guard, `is_headless`
  gate, `confirm`).

### Automated tests (bats, `tests/`)

- `statusbar.bats`: each block against stubbed commands and a fixture
  `SB_SYSFS`:
  - output format
  - hide conditions
  - warning thresholds
  - battery notify-once behaviour
  - `BLOCK_BUTTON` actions call the right command (stubs log their arguments)
- `lock.bats`:
  - i3lock-color path with and without cached image
  - xtrlock fallback
- `wallpaper.bats`:
  - picks from both sources
  - never writes into the wallpaper folder
  - writes the state file
  - renders lock image only when `magick` exists
- `dim-screen` restore on TERM.
- Installer: `config/dunst` link, `--wallpapers` dry-run leaves no trace,
  package lists contain the new names.
- `make lint` covers the new scripts.

### Build verification (local)

- `make` succeeds in each fork with the committed `config.h`.
- `diff config.def.h config.h` shows only the intended changes.

### Manual acceptance (user, in X)

Cannot be automated from a TTY session; checklist handed over at the end:

1. Keys: ❖ Enter, ❖ d, ❖ q, ❖ Shift+R keeps windows, ❖ Shift+L locks.
2. Bar:
   - every block renders
   - clicks and scrolls work
   - volume and brightness keys update instantly
3. Notifications:
   - right-click help appears
   - critical notifications stay until dismissed
4. Lock and idle:
   - lock screen shows blurred wallpaper, clock and ring states
   - idle dims at 9:30 and locks at 10:00
   - lid close locks, with no flash on resume
5. ❖ w changes the wallpaper and the next lock uses it.

## Out of scope

- st ergonomics: scrollback, keyboard selection, URL handling (sub-project 2).
- vanitygaps, swallow, scratchpads, other dwm patches (sub-project 3).
- dmenu scripts: power, screenshot, clipboard, emoji, wifi, iplocate fix (sub-project 4).
- Coloured status text (status2d).

## Risks

- **Submodule commits need pushing:** patches and `config.h` land as new
  commits in the dwm, dmenu, st and dwmblocks-async forks. The superproject
  only records their SHAs, so the user must push each fork before pushing this
  repo, or a fresh clone cannot check them out.
- **Suspend-time lock:** `restartsig` and `xss-lock` behaviour can only be
  confirmed in a live X session.
- **AUR dependency:** `i3lock-color` comes from the AUR and is unavailable on
  other distros; `bin/lock` degrades to xtrlock there by design.
