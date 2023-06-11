#!/bin/bash

# TODO(collins): add ~/.config/nvim/init.vim to dotfiles/ in this git repo
# TODO(collins): add ~/.config/X11 to dotfiles/ in this git repo
# TODO(collins): add ~/.vim to dotfiles/ in this git repo
# TODO(collins): add ~/.vimrc to dotfiles/ in this git repo

# This script will create links for the dotfiles.

# Step 1: ensure all necessary directories exist before linking files.
<<com 
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
com


function setup_dotfiles {
    echo -e "\u001b[7m Setting up Dotfiles... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}

function install_packages {
    echo -e "\u001b[7m Installing Packages.... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}

function install_extras {
    echo -e "\u001b[7m Installing Extras.... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}

function backup_configs {
    echo -e "\u001b[33;1m Backing up existing files... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}

function setup_symlinks {
    echo -e "\u001b[7m Setting up symlinks... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}

function setup_symlinks {
    echo -e "\u001b[7m Setting up symlinks... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}

function distro_tweaks {
    echo -e "\u001b[7m Distro specific tweaks... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}

# Menu TUI
echo -e "\u001b[32;1m Setting up Dotfiles...\u001b[0m"

echo -e " \u001b[37;1m\u001b[4mSelect an option:\u001b[0m"
echo -e "  \u001b[34;1m (0) Setup Everything \u001b[0m"
echo -e "  \u001b[34;1m (1) Install Packages \u001b[0m"
echo -e "  \u001b[34;1m (2) Install Extras \u001b[0m"
echo -e "  \u001b[34;1m (3) Backup Configs \u001b[0m"
echo -e "  \u001b[34;1m (4) Setup Symlinks \u001b[0m"
echo -e "  \u001b[34;1m (5) Distro Tweaks \u001b[0m"
echo -e "  \u001b[31;1m (*) Anything else to exit \u001b[0m"

echo -en "\u001b[32;1m ==> \u001b[0m"

read -r option


case $option in 

    "0")
        setup_dotfiles
        ;;

    "1")
        install_packages
        ;;

    "2")
        install_extras
        ;;

    "3")
        backup_configs
        ;;

    "4")
        setup_symlinks
        ;;

    "5")
        distro_tweaks
        ;;

    *)
        echo -e "\u001b[31;1m Invalid option entered, Bye! \u001b[0m"
        exit 0
        ;;
esac











