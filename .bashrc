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
alias ls='ls --color=auto'
alias df='df -h -x squashfs -x tmpfs -x devtmpfs'
alias lsmount='mount | column -t'
alias extip='curl icanhazip.com'
alias mem5='ps auxf | sort -nr -k 4 | head -5' # Top 5 process using the most memory
alias cpu5='ps auxf | sort -nr -k 4 | head -5' # Top 5 CPU hungry process
alias c='clear'
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
