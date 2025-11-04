#!/bin/bash

PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'

if [[ ${EUID} == 0 ]] ; then
    PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
else
    PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
fi

# Bind Ctrl+R to run the fzf-history function
#bind -x '"\C-r": fzf-history'

alias reload="source ~/.bashrc"

# Overriding $TERM
TERM=screen-256color

# Rust Bin
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# OCaml
command -v opam >/dev/null 2>&1 && eval $(opam env)

export PATH="$PATH:"$HOME"/.pub-cache/bin"

# Node Version Manager (NVM)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bash completions
[ -r /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion

# Common Environment Variables
if [ -f ~/.config/shell/envars.sh ]; then
    source ~/.config/shell/envars.sh
else
    echo "Warning: ~/.config/shell/envars.sh not found" >&2
fi

# Common functions
if [ -f ~/.config/shell/functions.sh ]; then
    source ~/.config/shell/functions.sh
else
    echo "Warning: ~/.config/shell/functions.sh not found" >&2
fi

# Common aliases
if [ -f ~/.config/shell/aliases.sh ]; then
    source ~/.config/shell/aliases.sh
else
    echo "Warning: ~/.config/shell/aliases.sh not found" >&2
fi
