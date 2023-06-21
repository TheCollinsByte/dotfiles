#!/bin/bash

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


# global scope definition
system_kind=""


# Distro specific package installs
function install_arch {
    sudo pacman -S \
        curl git vim neovim tmux openssh htop unzip bat
}

function install_debian {
    sudo apt install \
        curl git vim neovim tmux openssh htop unzip bat
}


function install_linux {
    # identify the Linux distribution
    if [[ -f "/etc/os-release" ]]; then
        source /etc/os-release
        if [[ "$ID" == "arch" ]]; then
            system_kind="Linux_Arch"
            install_arch
        elif [[ "$ID" == "debian" || "$ID_LIKE" == "debian" ]]; then
            system_kind="Linux_Debian"
            install_debian
            if [[ "$ID" == "ubuntu" ]]; then
                system_kind="Linux_Debian_Ubuntu"
            fi
            if [[ "$ID" == "linuxmint" ]]; then
                system_kind="Linux_Debian_Mint"
            fi
            if [[ "$ID" == "popos" ]]; then
                system_kind="Linux_Debian_Pop"
            fi
        elif [[ "$ID" == "fedora" ]]; then
            system_kind="Linux_Fedora"
        elif [[ "$ID" == "centos" ]]; then
            system_kind="Linux_CentOS"
        fi
    else
        system_kind="Linux_Unknown"
    fi
}


function install_packages {
    echo -e "\u001b[7m Installing Packages..... \u001b[0m"

    if [[ "$(uname)" == "Linux" ]]; then
        system_kind="Linux"
        install_linux
    # Check if the system is running Windows
    elif [[ "$(uname -s)" == "CYGWIN" ]]; then
        system_kind="Windows_Cygwin"
    elif [[ "$(uname -r)" == "Microsoft" ]]; then
        system_kind="Windows_WSL"
    else 
        system_kind="Unknown"
    fi

    echo -e "\u001b[7m Done! Installing packages for $system_kind \u001b[0m"
}


function install_vim_plugins {
    echo -e "\u001b[7m Installing plugin manager \u001b[0m"

    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    echo -e "\u001b[7m Installing plugins for vim and nvim \u001b[0m"

    vim +PlugUpdate +qall # Update and Quit several windows at a time.

    pip install neovim

    nvim -c UpdateRemotePlugins
}


<< required
    vim plugins, tmux plugins, bash plugins
required
function install_extras {
    echo -e "\u001b[7m Installing Extras.... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}

function backup_configs {
    echo -e "\u001b[33;1m Backing up existing files... \u001b[0m"

    echo -e "\u001b[36;1m Remove backups with 'rm -ir ~/.*.old && rm -ir ~/.config/*.old'. \u001b[0m"
}

function setup_symlinks {
    echo -e "\u001b[7m Setting up symlinks... \u001b[0m"

<< valid
    ln -sfnv "$PWD/.config/htop" ~/.config/
    ln -sfnv "$PWD/.config/nvim" ~/.config/
    ln -sfnv "$PWD/.config/shell" ~/.config/
    ln -sfnv "$PWD/.bashrc" ~/
    ln -sfnv "$PWD/.vimrc" ~/
    ln -sfnv "$PWD/.gitconfig" ~/
    ln -sfnv "$PWD/.tmux.conf" ~/
valid

    ln -sfnv "$PWD/dummy/README.md" ~/dummy/README.md

    echo -e "\u001b[7m Done! \u001b[0m"
}


function distro_tweaks {
    echo -e "\u001b[7m Distro specific tweaks... \u001b[0m"

    echo -e "\u001b[7m Done! \u001b[0m"
}


function setup_dotfiles {
    echo -e "\u001b[7m Setting up Dotfiles... \u001b[0m"
    install_packages
    install_extras
    backup_configs
    setup_symlinks
    distro_tweaks
    echo -e "\u001b[7m Done! \u001b[0m"
}


# Command-Line parameters
if ["$1" = "--all"] || ["$1" = "-a"]; then
   setup_dotfiles 
   exit 0
fi

if ["$1" = "--install"] || ["$1" = "-i"]; then
    install_packages 
    install_extras
    exit 0
fi

if ["$1" = "--symlinks"] || ["$1" = "-s"]; then
    setup_symlinks
    exit 0
fi

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

exit 0
