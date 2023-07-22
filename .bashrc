#
# ~/.bashrc
#

PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#PS1='[\u@\h \W]\$ '

if [[ ${EUID} == 0 ]] ; then
    PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
else
    PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
fi

alias reload="source ~/.bashrc"

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


# bash completions

# Common Environment Variables (Checking if the file exists and Evaluate the aliases script)
[ -f ~/.config/shell/envars.sh ] && source ~/.config/shell/envars.sh


# Common functions



# Common aliases (Checking if the file exists and Evaluate the aliases script)
[ -f ~/.config/shell/aliases.sh ] && source ~/.config/shell/aliases.sh
