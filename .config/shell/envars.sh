#!/bin/bash
# Environment Variables
export EDITOR=vim

# FZF (Fuzzy Finder)
export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude=.git --exclude=node_modules'
export FZF_COMPLETION_TRIGGER=','
export FZF_DEFAULT_OPTS="
--layout=reverse --info=inline --height=80% --multi --cycle --margin=1 --border=rounded
--preview '([[ -f {} ]] && (bat --style=numbers --color=always --line-range=:500 {} || cat {})) || ([[ -d {} ]] \
&& (exa -TFl --group-directories-first --icons -L 2 --no-user {} | less)) || echo {} 2> /dev/null | head -200'
--prompt=' ' --pointer='>' --marker='✔'
--color='hl:148,hl+:154,prompt:blue,pointer:032,marker:010,bg+:000,gutter:000'
--preview-window=right:65%
--bind '?:toggle-preview'
--bind 'ctrl-a:select-all'
--bind 'ctrl-y:execute-silent(echo {+} | clipcopy)'
--bind 'ctrl-e:execute(nvim-qt {+})'
--bind 'ctrl-v:execute(code {+})'"

export FZF_CTRL_T_COMMAND='fd -t f -HF -E=.git -E=node_modules'
export FZF_TMUX_OPTS='-p 90%'

# Go Bin
export PATH=$PATH:/usr/local/go/bin

# Gradle (Build Tool)
export PATH=$PATH:/opt/gradle/gradle-8.5/bin

# Flutter SDK
export PATH=$PATH:/opt/flutter/bin

# Exercism
export PATH=$PATH:/opt/exercism/
