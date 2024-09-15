#!/bin/bash

# Change directory and view the contents at the same time
function cl() {
	DIR="$*";
		# if no DIR given, go home
		if [ $# -lt 1 ]; then 
			DIR=$HOME;
		fi;
		builtin cd "${DIR}" && \
		# preferred ls command
		ls -F --color=auto
}

# show colors and codes
color() {
    local fgc bgc vals seq0

    printf "Color escapes are %s\n" '\e[${value};...;${value}m'
    printf "Values 30..37 are \e[33mforeground colors\e[m\n"
    printf "Values 40..47 are \e[43mbackground colors\e[m\n"
    printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

    # foreground colors
    for fgc in {30..37}; do
        # background colors
        for bgc in {40..47}; do
            fgc=${fgc#37} # white
            bgc=${bgc#40} # black

            vals="${fgc:+$fgc;}${bgc}"
            vals=${vals%%;}

            seq0="${vals:+\e[${vals}m}"
            printf "  %-9s" "${seq0:-(default)}"
            printf " ${seq0}TEXT\e[m"
            printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
        done
        echo
        echo
    done
}

# ex - archive extractor
ex() {
    if [ -f $1 ]; then
        case $1 in
        *.tar.bz2) tar xjf $1 ;;
        *.tar.gz) tar xzf $1 ;;
        *.bz2) bunzip2 $1 ;;
        *.rar) unrar x $1 ;;
        *.gz) gunzip $1 ;;
        *.tar) tar xf $1 ;;
        *.tbz2) tar xjf $1 ;;
        *.tgz) tar xzf $1 ;;
        *.zip) unzip $1 ;;
        *.Z) uncompress $1 ;;
        *.7z) 7z x $1 ;;
        *) echo "'$1' cannot be extracted via ex()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Runs when tab is pressed after ,
_fzf_comprun() {
    local command=$1
    shift

    case "$command" in
    cd) fzf "$@" --preview 'exa -TFl --group-directories-first --icons --git -L 2 --no-user {}' ;;
    nvim) fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' ;;
    vim) fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' ;;
    *) fzf "$@" ;;
    esac
}

# Function to run fzf and update history without line numbers
fzf-history() {
  BUFFER=$(history | sed 's/ *[0-9]* *//' | fzf --tac --query="$READLINE_LINE" --preview="echo {}")
  READLINE_LINE=$BUFFER
  READLINE_POINT=${#READLINE_LINE}
}
