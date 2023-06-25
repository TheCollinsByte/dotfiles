#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

# Overriding $TERM 
TERM=xterm-256color

# Gradle (Build Tool)
export PATH=$PATH:/opt/gradle/gradle-7.6.1/bin

# Flutter SDK
export PATH=$PATH:/opt/flutter/bin

# Exercism
export PATH=$PATH:/opt/bin/

# Shell Aliase's
alias lock='xtrlock -b'
alias intellij='wmname LG3D ; /opt/idea-IC-222.4167.29/bin/idea.sh'
alias aside='wmname LG3D ; /opt/android-studio/bin/studio.sh'
alias ls='ls --color=auto'
alias df='df -h -x squashfs -x tmpfs -x devtmpfs'
alias lsmount='mount | column -t'
alias extip='curl icanhazip.com'
alias mem5='ps auxf | sort -nr -k 4 | head -5' # Top 5 process using the most memory
alias cpu5='ps auxf | sort -nr -k 4 | head -5' # Top 5 CPU hungry process
alias c='clear'
alias pupgrade='sudo pacman -Syu'   # Upgrade the System
alias pclean='sudo pacman -Scc'     # Clean the cache 
alias yupgrade='yay -Syu'           # Fetch the database from the official repositories, update all your official packages and the packages from the AUR
alias yclean='yay -Sc --aur'        # Clean AUR Cache
alias pyclean='yay -Sc'             # Clean both the pacman and yay caches
alias py='python3'
alias cat='bat --paging=never'


# To Work on the System maintenance
#alias i='sudo pacman -S' # i or install
#alias update='sudo pacman -Syy'


# Node Version Manager (NVM)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Rust Bin
. "$HOME/.cargo/env" 
