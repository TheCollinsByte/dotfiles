# Desktop

dwm with Super as the mod key, gruvbox dark and FiraCode Nerd Font across
dwm, dmenu, st and dunst. Design: `docs/superpowers/specs/2026-10-01-dwm-foundations-design.md`.

## Keys

❖ = Super.

| Key | Action |
|---|---|
| ❖ Enter | terminal (st) |
| ❖ d | dmenu launcher |
| ❖ q | close window |
| ❖ Shift+Enter | swap with master |
| ❖ j / k | focus next / previous |
| ❖ h / l | shrink / grow master |
| ❖ i / o | more / fewer masters |
| ❖ t / f / m | tile / float / monocle |
| ❖ Space | previous layout |
| ❖ Shift+Space | float window |
| ❖ b | hide / show bar |
| ❖ 1–9 / ❖ Shift+1–9 | view tag / send window to tag |
| ❖ 0 / ❖ Shift+0 | view all / tag all |
| ❖ Tab | previous tag |
| ❖ , / . (Shift: send) | focus / send to other monitor |
| ❖ w | next wallpaper |
| ❖ n / ❖ Shift+N | dismiss / recall notification |
| ❖ Shift+L | lock |
| ❖ Shift+R | restart dwm in place (windows kept) |
| ❖ Shift+Q | quit dwm (log out) |
| Volume up / down / mute | ±5% / toggle, bar updates instantly |
| Brightness up / down | ±5%, bar updates instantly |
| Play, Next, Prev | media control |

## Status bar

Blocks hide when they have nothing to show. **Left click** runs the main
action, **right click** explains the block, **scroll** adjusts where it makes
sense.

| Block | Shows | Hidden when | Left click | Scroll |
|---|---|---|---|---|
| music | `▶ Artist – Title` | no player | play / pause | next / previous |
| network | `📶 70%`, `🌐`, `❌` | — | nmtui | — |
| cpu | `💻 12%`, `🔥` ≥ 90% | — | htop by CPU | — |
| memory | `🧠 13.8/23.2G`, `🔥` ≥ 90% | — | htop by memory | — |
| disk | `💾 61%`, `⚠` ≥ 90% | — | all disks | — |
| keyboard | `⌨ us` | one layout | next layout | — |
| volume | `🔊 45%`, `🔇` | no audio server | mute | ±5% |
| brightness | `💡 70%` | no backlight | — | ±5% |
| battery | `🔋 82%`, `⚡`, `🪫` < 20% | no battery, full on AC | status and time left | — |
| clock | `Thu Oct 01 10:41` | — | month calendar | — |

Below 10% on battery you get one critical notification per discharge.
The scripts live in `bin/statusbar/`; the block table is
`suckless/dwmblocks/config.h` (dwmblocks-async).

## Lock and idle

- `lock` (also ❖ Shift+L and the `l` alias) shows i3lock-color over a
  blurred copy of the current wallpaper with a clock and a gruvbox ring:
  yellow idle, green typing, red wrong, blue checking.
- Without i3lock-color it falls back to `xtrlock -b`.
- Idle: the screen dims at 9:30, locks at 10:00, and the display turns off
  at 15 minutes.
- The screen locks before suspend and lid close, with no flash of content on
  resume (`lock-sleep-wrapper`).

## Wallpapers

- `wallpaper-shuffle.sh` (❖ w) picks from `~/.config/wallpapers` and, if
  present, `~/.local/share/wallpapers/gruvbox`. It never writes into those
  folders.
- The current choice is recorded in `~/.local/state/dotfiles/wallpaper`.
- `./install.sh --wallpapers` downloads the curated gruvbox "minimalistic"
  set (~58 MB). It is not committed to the repo.

## Rebuilding

```bash
./install.sh -b        # build and install dwm, dmenu, st, dwmblocks (sudo)
```

Then ❖ Shift+R reloads dwm without closing windows. Restart dwmblocks with
`pkill dwmblocks; dwmblocks &`.

## Acceptance checklist

Run once in a live X session after installing:

- [ ] Keys:
  - ❖ Enter, ❖ d and ❖ q work
  - ❖ Shift+R keeps windows open
  - ❖ Shift+L locks
- [ ] Bar:
  - every block renders
  - clicks and scrolls work
  - volume and brightness keys update it instantly
- [ ] Notifications:
  - right-click help appears
  - a critical notification stays until dismissed
- [ ] Lock and idle:
  - the lock screen shows the blurred wallpaper, clock and ring states
  - idle dims at 9:30 and locks at 10:00
  - closing the lid locks, with no flash on resume
- [ ] ❖ w changes the wallpaper, and the next lock uses it
