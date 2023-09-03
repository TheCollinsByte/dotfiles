#!/bin/bash

# Wallpaper Shuffle
DIR="/home/$USER/.scripts/wallpapers"

WAL="$(ls $DIR/*.png | shuf -n1)"

cat $WAL > /home/$USER/.config/wallpapers/wallpaper.png

feh --bg-scale /home/$USER/.config/wallpapers/wallpaper.png
