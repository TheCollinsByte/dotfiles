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
  [ -x "$f" ] && . "$f"
 done
 unset f
fi


# Keyboard Layout
setxkbmap uk &


# Display Resolution
xrandr --output Virtual-1 --mode 1920x1080 &


# compositor
picom -f &


# redshift
redshift -l -6:34 -t 5500:2500 &


# slstatus While be changed to dmenu
slstatus &

# Load Wallpaper with (FEH)
~/.scripts/wallpaper-shuffle.sh

# DWM Loop
# dwm &
# while true; do
	# dwm >/dev/null 2>&1
# done

# Execute DWM
exec dwm
