# shellcheck shell=bash disable=SC1090
# Login shells: everything lives in .bashrc (which sources envars.sh).
# PATH additions belong in config/shell/envars.sh, not here — tool installers
# like to append lines to this file; move them there.
[[ -f ~/.bashrc ]] && . ~/.bashrc
