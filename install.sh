#!/bin/bash

# This script will create links for the dotfiles.

##########
#  nvim  #
##########
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.config/nvim/undo"
ln -sf "$HOME/dotfiles/nvim/init.vim" "$HOME/.config/nvim/init.vim"


##############
# Xresources #
##############
ln -sfn "$HOME/dotfiles/X11" "$HOME/.config"


########
#  vim #
########
ln -s "$HOME/dotfiles/vim/.vim" "$HOME/.vim"
ln -s "$HOME/dotfiles/vim/.vimrc" "$HOME/.vimrc"
