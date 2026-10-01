#!/bin/bash
# Sourced files live in $HOME, which shellcheck cannot resolve from the repo.
# shellcheck disable=SC1090,SC1091

# Environment first, so non-interactive shells (ssh host cmd, scp) still get
# PATH and friends. envars.sh is idempotent, so `reload` adds nothing twice.
if [ -f ~/.config/shell/envars.sh ]; then
    source ~/.config/shell/envars.sh
else
    echo "Warning: ~/.config/shell/envars.sh not found" >&2
fi

# Everything below is for interactive shells only.
[[ $- != *i* ]] && return

PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'

if [[ ${EUID} == 0 ]] ; then
    PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
else
    PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
fi

# Bind Ctrl+R to run the fzf-history function
#bind -x '"\C-r": fzf-history'

alias reload="source ~/.bashrc"

# OCaml — one opam call (it forks a process, so don't run it twice)
if command -v opam >/dev/null 2>&1; then
    eval "$(opam env --shell=bash --set-switch 2>/dev/null)"
fi

# Node Version Manager (NVM), lazy-loaded: sourcing nvm.sh costs ~150ms per
# shell. The default node's bin goes on PATH directly so node, npm and
# globally installed CLIs work immediately; nvm itself loads on first use.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    _nvm_default=$(cat "$NVM_DIR/alias/default" 2>/dev/null)
    if [ -d "$NVM_DIR/versions/node/$_nvm_default/bin" ]; then
        pathadd "$NVM_DIR/versions/node/$_nvm_default/bin"
        nvm() {
            unset -f nvm
            \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
            nvm "$@"
        }
    else
        # Default alias is a range ("22", "lts/*") only nvm can resolve.
        \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
    unset _nvm_default
fi

# bash completions
[ -r /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion

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

# Claude Free aliases — only where the wrappers exist, so `claude` still
# works on machines without them.
command -v claude-free >/dev/null 2>&1 && alias claude="claude-free"
command -v claude-team >/dev/null 2>&1 && alias ct="claude-team"

# Non-zero status from the test above must not become the shell's first $?.
true
