#!/bin/bash

DIR="/home/$USER/.scripts/wallpapers"

WAL="$(ls $DIR/*.png | shuf -n1)"

cat $WAL > /home/$USER/.scripts/wallpapers/wallpaper.png

feh --bg-scale /home/$USER/.scripts/wallpapers/wallpaper.png
