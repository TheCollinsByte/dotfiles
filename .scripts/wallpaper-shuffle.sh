#!/bin/sh

# Wallpaper Shuffle
exec > >(tee -ia "$(readlink -f "$(dirname "$0")")/wallpaper-shuffle.log")
exec 2>&1

DIR="/home/$USER/.config/wallpapers"

if [ -z "$(find "$DIR" -name '*.png' -print -quit)" ]; then
    echo "FEH Script: No PNG files found in $DIR. Exiting."
    exit 1
fi

while true; do
    WAL="$(ls "$DIR"/*.png | shuf -n1)"

    echo "Checking $WAL"
    if [ -s "$WAL" ] && file --mime-type -b "$WAL" | grep -q '^image/'; then
        break
    else
        echo "FEH Script: Wallpaper File is empty or not a valid image. Shuffling again..."
    fi
done

cp "$WAL" "$DIR/wallpaper.png"

feh --no-fehbg --bg-scale "$DIR/wallpaper.png"

