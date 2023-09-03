#!/bin/sh

# Wallpaper Shuffle
DIR="/home/$USER/./.config/wallpapers/"

WAL="$(ls $DIR/*.png | shuf -n1)"

cat $WAL > /home/$USER/.config/wallpapers/wallpaper.png

feh --no-fehbg --bg-scale /home/$USER/.config/wallpapers/wallpaper.png
