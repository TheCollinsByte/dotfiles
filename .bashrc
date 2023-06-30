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

# Node Version Manager (NVM)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Rust Bin
. "$HOME/.cargo/env" 
