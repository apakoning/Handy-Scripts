#!/usr/bin/env bash
set -euo pipefail

echo "[HiFi] Stopping desktop audio stack (PipeWire/Pulse)…"
systemctl --user stop wireplumber.service pipewire-pulse.service pipewire.service || true
systemctl --user stop pipewire-pulse.socket pipewire.socket || true

# Make sure no stray daemons will auto-spawn
pkill -9 pipewire pipewire-pulse wireplumber pulseaudio 2>/dev/null || true

echo "[HiFi] Detecting Khadas Tea ALSA hw device…"
HW_LINE="$(aplay -L | awk '/^hw:.*(Tea|TEA|KHADAS|Khadas)/{print; exit}')"
if [[ -z "$HW_LINE" ]]; then
  echo "  Could not find a 'hw:' device for Tea via aplay -L."
  echo "  Try: aplay -l   and look for the card/device numbers (e.g. card 0, device 0)."
  exit 1
fi
echo "  Using $HW_LINE"

echo
echo "[HiFi] Example mpv commands (bit-perfect, exclusive):"
echo "  mpv --no-config --ao=alsa --audio-device=alsa/${HW_LINE} --audio-exclusive=yes \\"
echo "      --volume=100 --replaygain=no  /path/to/track.flac"
echo
echo "Tip: Strawberry can also be set to use ALSA directly (see notes below)."

