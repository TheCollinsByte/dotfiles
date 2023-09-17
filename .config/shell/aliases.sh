#!/bin/bash

# Aliases
alias q="exit"
alias ls='ls --color=auto'

alias intellijc='wmname LG3D ; /opt/intellij/idea-IC-231.9225.16/bin/idea.sh'
alias intelliju='wmname LG3D ; /opt/intellij/idea-IU-232.8660.185/bin/idea.sh'
alias e='/opt/Electrum-4.4.5/run_electrum'

alias l='xtrlock -b'

alias pupgrade='sudo pacman -Syu'   # Upgrade the System
alias pclean='sudo pacman -Scc'     # Clean the cache
alias yupgrade='yay -Syu'           # Fetch the database from the official repositories, update all your official packages and the packages from the AUR
alias yclean='yay -Sc --aur'        # Clean AUR Cache
alias pyclean='yay -Sc'             # Clean both the pacman and yay caches

alias tmux="tmux -u"


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

alias lt='ls --human-readable --size -1 -S --classify'      # Sort by file size
alias mnt="mount | awk -F' ' '{ printf \"%s\t%s\n\",\$1,\$3; }' | column -t | egrep ^/dev/ | sort"      # View only mounted drives
alias left='ls -t -1'   # Sort By modification time
alias gh='history|grep'     # Find a command in your grep history
alias count='find . -type f | wc -l'
alias cpv='rsync -ah --info=progress2'      # A Copy progress bar

# Create a Python  Virtual Environment
alias ve='python3 -m venv ./venv'
alias va='source ./venv/bin/activate'

alias tcn='mv --force -t ~/.local/share/Trash '
