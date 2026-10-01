#!/bin/sh

# Environment for everything started below — dwmblocks click handlers need
# $TERMINAL/$EDITOR and PATH even when X is launched by a display manager.
# shellcheck source=config/shell/envars.sh
[ -f "$HOME/.config/shell/envars.sh" ] && . "$HOME/.config/shell/envars.sh"

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps
if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"

fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  # shellcheck source=/dev/null
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

# Session log: everything started in the background writes here, so a daemon
# that dies or was never installed leaves a trace. Trimmed to the last 2000
# lines each login.
log="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/xsession.log"
mkdir -p "$(dirname "$log")"
[ -f "$log" ] && tail -n 2000 "$log" > "$log.tmp" && mv -f "$log.tmp" "$log"
printf '\n=== X session %s (DISPLAY=%s) ===\n' "$(date '+%F %T')" "$DISPLAY" >> "$log"

# start PROG [ARGS...]: run PROG in the background if it is installed, with
# its output in the session log; otherwise note that it was skipped.
start() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "xinitrc: $1 not installed, skipped" >> "$log"
        return 0
    fi
    "$@" >> "$log" 2>&1 &
}

# Hand this display to tmux (panes created from now on) and to the user
# service manager, so programs started there can reach X too. Shells that
# already exist pick it up from envars.sh on their next `reload`.
if command -v tmux >/dev/null 2>&1; then
    tmux set-environment -g DISPLAY "$DISPLAY" 2>/dev/null
    [ -n "${XAUTHORITY:-}" ] && tmux set-environment -g XAUTHORITY "$XAUTHORITY" 2>/dev/null
fi
command -v dbus-update-activation-environment >/dev/null 2>&1 &&
    dbus-update-activation-environment --systemd DISPLAY XAUTHORITY >> "$log" 2>&1

# Keyboard Layout
setxkbmap uk

# Display Resolution — VM display only; set it before the wallpaper so feh
# scales to the final size.
if xrandr 2>/dev/null | grep -q '^Virtual-1 connected'; then
    xrandr --output Virtual-1 --mode 1920x1080
fi

# Idle: screensaver event at 9:30 (dim), lock 30s later; display off at 15 min.
# noblank: without it Xorg blanks the screen itself at 9:30 instead of dimming.
xset s noblank
xset s 570 30
xset dpms 0 0 900

# compositor
start picom -f

# notifications
start dunst

# Lock on idle and before suspend, dimming first.
start xss-lock --transfer-sleep-lock -n dim-screen -- lock-sleep-wrapper lock

# redshift
start redshift -l -6:34 -t 5500:2500

# Wallpaper (also renders the lock-screen image)
start wallpaper-shuffle.sh

start dwmblocks

# Audio routing
start fix-audio.sh

exec dwm
