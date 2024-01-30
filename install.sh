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
    packages_to_install=(
        curl git vim neovim tmux openssh htop unzip lsd calibre okular
        bluez bluez-utils cmus fzf xtrlock fd feh aws-cli yay ripgrep htop man-db
        wmname redshift bat iftop
   )

   for package in "${packages_to_install[@]}"; do
        if ! pacman -Qs "$package" > /dev/null; then
            echo "Installing $package..."
            sudo pacman -S "$package"
        else
            echo "$package is already installed. Skipping..."
        fi
    done
}

function install_debian {
    packages_to_install=(
        curl git vim neovim tmux openssh htop unzip lsd htop
        cmus fzf xtrlock fd-find feh awscli ripgrep calibre okular man-db
        wmname redshift bat iftop
   )

   for package in "${packages_to_install[@]}"; do
        if ! dpkg -l "$package" > /dev/null; then
            echo "Installing $package..."
            sudo apt install "$package"
        else
            echo "$package is already installed. Skipping..."
        fi
    done

    # Create symbolic links
    sudo ln -sfnv /usr/bin/fdfind /usr/bin/fd
    sudo ln -sfnv /usr/bin/batcat /usr/bin/bat
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


function install_tmux_plugins {
    echo -e "\u001b[7m Installing tmux plugin \u001b[0m"

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    tmux start-server           # Start tmux server, If not running, without creating any session
    tmux new-session -d
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    tmux kill-server

    echo -e "\u001b[7m Done... \u001b[0m"
}

<< required
    vim plugins, tmux plugins, bash plugins
required
function install_extras {
    echo -e "\u001b[7m Installing Extras.... \u001b[0m"
    install_vim_plugins
    install_tmux_plugins
    echo -e "\u001b[7m Done! \u001b[0m"
}

function backup_configs {
    echo -e "\u001b[33;1m Backing up existing files... \u001b[0m"

    echo -e "\u001b[36;1m Remove backups with 'rm -ir ~/.*.old && rm -ir ~/.config/*.old'. \u001b[0m"
}


function setup_symlinks {
    echo -e "\u001b[7m Setting up symlinks... \u001b[0m"

    declare -a symlinks=(
        "$PWD/.config/cmus:$HOME/.config/cmus"
        "$PWD/.xinitrc:$HOME/.xinitrc"
        "$PWD/.config/ranger:$HOME/.config/ranger"
        "$PWD/.config/fontconfig:$HOME/.config/fontconfig"
        "$PWD/.config/bat:$HOME/.config/bat"
        "$PWD/.config/htop:$HOME/.config/htop"
        "$PWD/.config/nvim:$HOME/.config/nvim"
        "$PWD/.config/shell:$HOME/.config/shell"
        "$PWD/.bashrc:$HOME/.bashrc"
        "$PWD/.dmenurc:$HOME/.dmenurc"
        "$PWD/.dircolors:$HOME/.dircolors"
        "$PWD/.vimrc:$HOME/.vimrc"
        "$PWD/.gitconfig:$HOME/.gitconfig"
        "$PWD/.tmux.conf:$HOME/.tmux.conf"
        "$PWD/.scripts:$HOME/.scripts"
        "$PWD/.bash_profile:$HOME/.bash_profile"
    )

    for link in "${symlinks[@]}"; do
        IFS=':' read -r source_path destination_path <<< "$link"

        if [ -e "$source_path" ]; then
            if [ ! -e "$destination_path" ]; then
                mkdir -p "$(dirname "$destination_path")"
                ln -sfnv "$source_path" "$destination_path"

                if [ $? -ne 0 ]; then
                    echo "Error creating symlink for $source_path"
                fi
            else
                read -p "$destination_path already exists. Do you want to overwrite? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm -rf "$destination_path"
                    ln -sfnv "$source_path" "$destination_path"
                    if [ $? -ne 0 ]; then
                        echo "Error creating symlink for $source_path"
                    fi
                else
                    echo "Skipping $destination_path"
                fi
            fi
        else
            echo "$source_path does not exist. Skipping symlink creation."
        fi
    done

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
if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
   setup_dotfiles 
   exit 0
fi

if [ "$1" = "--install" ] || [ "$1" = "-i" ]; then
    install_packages 
    install_extras
    exit 0
fi

if [ "$1" = "--symlinks" ] || [ "$1" = "-s" ]; then
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
