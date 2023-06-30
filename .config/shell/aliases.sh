#!/bin/bash

# Aliases
alias intellij='wmname LG3D ; /opt/idea-IC-222.4167.29/bin/idea.sh'
alias aside='wmname LG3D ; /opt/android-studio/bin/studio.sh'

alias lock='xtrlock -b'

alias pupgrade='sudo pacman -Syu'   # Upgrade the System
alias pclean='sudo pacman -Scc'     # Clean the cache
alias yupgrade='yay -Syu'           # Fetch the database from the official repositories, update all your official packages and the packages from the AUR
alias yclean='yay -Sc --aur'        # Clean AUR Cache
alias pyclean='yay -Sc'             # Clean both the pacman and yay caches
