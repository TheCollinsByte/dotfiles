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

# compositor
picom -f &

# redshift
redshift -l -6:34 -t 5500:2500 &

# Load Wallpaper with (FEH)
~/.local/bin/wallpaper-shuffle.sh &

dwmblocks &

# Audio routing
~/.local/bin/fix-audio.sh &

exec dwm
