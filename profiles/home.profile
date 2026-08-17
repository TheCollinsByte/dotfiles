# Profile: home — personal desktop.
#
# The full desktop plus the media tooling that only makes sense on a personal
# machine.

# All PROFILE_* variables are read by lib/profiles.sh after sourcing.
# shellcheck shell=bash disable=SC2034

PROFILE_DESCRIPTION="Personal desktop with media tooling"

PROFILE_SERVER_MODE=false
PROFILE_MINIMAL_MODE=false

PROFILE_EXTRA_PACKAGES=(cmus feh mpv)

PROFILE_SKIP_CONFIGS=()
