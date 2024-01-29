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


# Rust Bin
. "$HOME/.cargo/env"


# OCaml
eval $(opam env)


# Node Version Manager (NVM)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# bash completions


# Common Environment Variables (Checking if the file exists and Evaluate the aliases script)
[ -f ~/.config/shell/envars.sh ] && source ~/.config/shell/envars.sh


# Common functions
[ -f ~/.config/shell/functions.sh ] && source ~/.config/shell/functions.sh


# Common aliases (Checking if the file exists and Evaluate the aliases script)
[ -f ~/.config/shell/aliases.sh ] && source ~/.config/shell/aliases.sh

