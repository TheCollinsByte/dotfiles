#!/bin/sh

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
# noblank: without it Xorg blanks the screen itself at 9:30 instead of dimming.
xset s noblank
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
