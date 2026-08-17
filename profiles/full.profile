# Profile: full — a complete desktop workstation.
#
# Everything: suckless tools, X configs, media, fonts. This is what the bare
# `--all` install does; the profile exists so it can be named explicitly.

# All PROFILE_* variables are read by lib/profiles.sh after sourcing.
# shellcheck shell=bash disable=SC2034

PROFILE_DESCRIPTION="Complete desktop workstation (suckless, X, media)"

PROFILE_SERVER_MODE=false
PROFILE_MINIMAL_MODE=false

PROFILE_EXTRA_PACKAGES=()
PROFILE_SKIP_CONFIGS=()
