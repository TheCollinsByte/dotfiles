#!/bin/sh
# Route audio to HDMI only when a display is connected; otherwise use analog out.
# Also unmute ALSA channels that come up muted at boot.
#
# The card is discovered, not hardcoded; set FIX_AUDIO_CARD to a PulseAudio/
# PipeWire card name (see `pactl list cards short`) to pick a different one.

for _ in 1 2 3 4 5 6 7 8 9 10; do
    pactl info >/dev/null 2>&1 && break
    sleep 1
done
pactl info >/dev/null 2>&1 || exit 0

CARD=${FIX_AUDIO_CARD:-$(pactl list cards short | awk '$2 ~ /^alsa_card\.pci-/ {print $2; exit}')}
[ -n "$CARD" ] || exit 0
ANALOG="alsa_output.${CARD#alsa_card.}.analog-stereo"

# ALSA index of that card, for amixer.
ALSA_INDEX=$(pactl list cards | awk -v card="$CARD" '
    $1 == "Name:" { inside = ($2 == card) }
    inside && $1 == "alsa.card" { gsub(/"/, "", $3); print $3; exit }')

if [ -n "$ALSA_INDEX" ]; then
    # Speaker/Headphone are output pin amps, not the user's volume: raise them
    # so Master alone sets loudness. Master is only unmuted, never turned up.
    for ctl in Speaker Headphone; do
        amixer -q -c "$ALSA_INDEX" sset "$ctl" 100% unmute 2>/dev/null
    done
    amixer -q -c "$ALSA_INDEX" sset Master unmute 2>/dev/null
fi

for status in /sys/class/drm/card*-HDMI-*/status; do
    [ -r "$status" ] && grep -qx connected "$status" && exit 0
done

pactl set-card-profile "$CARD" output:analog-stereo+input:analog-stereo || exit 1
sleep 1
pactl set-default-sink "$ANALOG"
pactl set-sink-mute "$ANALOG" 0
for i in $(pactl list sink-inputs short | awk '{print $1}'); do
    pactl move-sink-input "$i" "$ANALOG"
done
