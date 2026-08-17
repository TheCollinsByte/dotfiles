# Profile: minimal — headless server or container.
#
# Shell, editor and terminal multiplexer only. No X, no suckless, no build
# tooling, no media.

# All PROFILE_* variables are read by lib/profiles.sh after sourcing.
# shellcheck shell=bash disable=SC2034

PROFILE_DESCRIPTION="Headless: shell, vim and tmux only"

PROFILE_SERVER_MODE=true
PROFILE_MINIMAL_MODE=true

PROFILE_EXTRA_PACKAGES=()

# Belt and braces: server mode already skips these, but naming them keeps the
# profile honest if it is ever used without SERVER_MODE.
PROFILE_SKIP_CONFIGS=(.xinitrc .Xresources .dmenurc cmus fontconfig suckless)
