#!/bin/bash

# Aliases
alias q="exit"
alias ls='ls --color=auto'

alias intellij='wmname LG3D ; /opt/idea-IC-231.9225.16/bin/idea.sh'

alias l='xtrlock -b'

alias pupgrade='sudo pacman -Syu'   # Upgrade the System
alias pclean='sudo pacman -Scc'     # Clean the cache
alias yupgrade='yay -Syu'           # Fetch the database from the official repositories, update all your official packages and the packages from the AUR
alias yclean='yay -Sc --aur'        # Clean AUR Cache
alias pyclean='yay -Sc'             # Clean both the pacman and yay caches


alias py='python3'

alias df='df -h -x squashfs -x tmpfs -x devtmpfs'
alias lsmount='mount | column -t'
alias extip='curl icanhazip.com'
alias mem5='ps auxf | sort -nr -k 4 | head -5' # Top 5 process using the most memory
alias cpu5='ps auxf | sort -nr -k 4 | head -5' # Top 5 CPU hungry process


alias c='clear'
alias cat='bat --paging=never'

alias vimrc="vim ~/.vimrc"
alias nvimrc="nvim ~/.config/nvim/init.vim"
alias bashrc="$EDITOR ~/.bashrc"
alias alia="$EDITOR ~/.config/shell/aliases.sh"
alias enva="$EDITOR ~/.config/shell/envars.sh"

alias k="kubectl" 
