#!/bin/bash

# TODO(collins): add ~/.config/nvim/init.vim to dotfiles/ in this git repo
# TODO(collins): add ~/.config/X11 to dotfiles/ in this git repo
# TODO(collins): add ~/.vim to dotfiles/ in this git repo
# TODO(collins): add ~/.vimrc to dotfiles/ in this git repo

# This script will create links for the dotfiles.

# Step 1: ensure all necessary directories exist before linking files.
for dir in $(find * -mindepth 1 -type d ! -name '.git'); do

	target="$HOME/${dir#dotfiles/}"
	echo "INFO: Ensuring directory exists: $target"
	mkdir -p $target

    # Step 2: create links for all dotfiles
    for file in $(find dir -mindepth 1 -type f); do
        source=$PWD/$file
        target="$HOME/${file#dotfiles/}"
        # This if statement could be replaced by passing -f to ln,
        # but doing so could accidentally delete a dotfile that hasn't been
        # added to this repo yet, which is why -f is not used, and instead
        # a warning is printed to inform the user about the situation.
        if [ -e "$target" ]; then
            if [ ! -L "$target" ]; then
                echo "WARN: $target exists but is not a symlink, skipping it."
            else
                echo "INFO: $target is already a symlink, skipping it."
            fi
        else
            echo "INFO: linking $source to $target"
            ln -s $source $target
        fi
    done
done

