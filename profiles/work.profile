# Profile: work — desktop for a work machine.
#
# Keeps the full desktop environment but drops the personal media configs, and
# adds the container and cloud tooling a work machine usually needs.
#
# Git identity is deliberately not set here — it belongs in
# ~/.gitconfig.local, which is never tracked.

# All PROFILE_* variables are read by lib/profiles.sh after sourcing.
# shellcheck shell=bash disable=SC2034

PROFILE_DESCRIPTION="Work desktop: dev tooling, no personal media"

PROFILE_SERVER_MODE=false
PROFILE_MINIMAL_MODE=false

PROFILE_EXTRA_PACKAGES=(docker jq make)

# Personal music setup has no place on a work machine.
PROFILE_SKIP_CONFIGS=(cmus)
