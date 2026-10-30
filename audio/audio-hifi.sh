#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --restore) systemctl --user start pipewire.socket pipewire-pulse.socket wireplumber.service; exit 0 ;;
  -h|--help) echo "Usage: $0 [--restore]"; echo "Temporarily stop desktop audio for a detected Khadas Tea device, or restore PipeWire."; exit 0 ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

echo "[HiFi] Detecting Khadas Tea ALSA hw device…"
HW_LINE="$(aplay -L | awk '/^hw:.*(Tea|TEA|KHADAS|Khadas)/{print; exit}')"
if [[ -z "$HW_LINE" ]]; then
  echo "  Could not find a 'hw:' device for Tea via aplay -L."
  echo "  Try: aplay -l   and look for the card/device numbers (e.g. card 0, device 0)."
  exit 1
fi
echo "[HiFi] Stopping desktop audio stack (PipeWire/Pulse)…"
systemctl --user stop wireplumber.service pipewire-pulse.service pipewire.service || true
systemctl --user stop pipewire-pulse.socket pipewire.socket || true

# Make sure no stray daemons will auto-spawn
for process in pipewire pipewire-pulse wireplumber pulseaudio; do
  pkill -u "$(id -u)" -x "$process" 2>/dev/null || true
done

echo "  Using $HW_LINE"

echo
echo "[HiFi] Example mpv commands (bit-perfect, exclusive):"
echo "  mpv --no-config --ao=alsa --audio-device=alsa/${HW_LINE} --audio-exclusive=yes \\"
echo "      --volume=100 --replaygain=no  /path/to/track.flac"
echo
echo "Tip: Strawberry can also be set to use ALSA directly (see notes below)."


