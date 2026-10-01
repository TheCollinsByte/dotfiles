#!/bin/sh
# Environment Variables
#
# Sourced by .bashrc and by .xinitrc (/bin/sh), so keep this file POSIX.
# Safe to source repeatedly: PATH entries are only added once.

# Add a directory to PATH if it exists and is not already there.
# pathadd DIR          -> prepend (takes precedence over system binaries)
# pathadd DIR after    -> append
pathadd() {
    [ -d "$1" ] || return 0
    case ":$PATH:" in
        *":$1:"*) ;;
        *) if [ "${2:-}" = after ]; then PATH="$PATH:$1"; else PATH="$1:$PATH"; fi ;;
    esac
}

export EDITOR=nvim
export TERMINAL=st

# FZF (Fuzzy Finder)
export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude=.git --exclude=node_modules'
export FZF_COMPLETION_TRIGGER=','
export FZF_DEFAULT_OPTS="
--layout=reverse --info=inline --height=80% --multi --cycle --margin=1 --border=rounded
--preview '([[ -f {} ]] && (bat --style=numbers --color=always --line-range=:500 {} || cat {})) || ([[ -d {} ]] \
&& (eza -TFl --group-directories-first --icons -L 2 --no-user {} | less)) || echo {} 2> /dev/null | head -200'
--prompt=' ' --pointer='>' --marker='✔'
--color='hl:148,hl+:154,prompt:blue,pointer:032,marker:010,bg+:000,gutter:000'
--preview-window=right:65%
--bind '?:toggle-preview'
--bind 'ctrl-a:select-all'
--bind 'ctrl-y:execute-silent(echo {+} | xclip -selection clipboard)'
--bind 'ctrl-e:execute(nvim {+})'"

export FZF_CTRL_T_COMMAND='fd -t f -HF -E=.git -E=node_modules'
export FZF_TMUX_OPTS='-p 90%'

# Toolchains and SDKs (appended: system binaries win)
pathadd /usr/local/go/bin after
pathadd /opt/gradle/gradle-9.3.1/bin after
pathadd /opt/flutter/bin after
pathadd /opt/exercism after
pathadd "$HOME/.pub-cache/bin" after
pathadd "$HOME/.lmstudio/bin" after

# User-installed tools (prepended: these win over system binaries)
pathadd "$HOME/.cargo/bin"
export BUN_INSTALL="$HOME/.bun"
pathadd "$BUN_INSTALL/bin"
pathadd "$HOME/.opencode/bin"
pathadd "$HOME/.local/share/pi-node/current/bin"

# Custom scripts and statusbar blocks (highest precedence)
pathadd "$HOME/.local/bin"
pathadd "$HOME/.local/bin/statusbar"

export PATH
