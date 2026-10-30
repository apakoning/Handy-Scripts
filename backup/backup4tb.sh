#!/usr/bin/env bash
# Mirror between mounted filesystems; preview unless --apply is explicit.
set -euo pipefail
SRC="${BACKUP_SOURCE:-/mnt/HDD4TB}"
DEST="${BACKUP_DESTINATION:-/mnt/Backup4TB}"
APPLY=0
case "${1:-}" in
  --apply) APPLY=1 ;;
  ""|--dry-run) ;;
  -h|--help) echo "Usage: $0 [--dry-run|--apply]"; echo "Set BACKUP_SOURCE and BACKUP_DESTINATION to mounted directories."; exit 0 ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac
for command in rsync mountpoint realpath; do
  command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }
done
SRC="$(realpath -e -- "$SRC")"
DEST="$(realpath -e -- "$DEST")"
[[ "$SRC" != / && "$DEST" != / && "$SRC" != "$DEST" && "$DEST/" != "$SRC/"* && "$SRC/" != "$DEST/"* ]] || { echo "Source and destination must be separate non-root paths." >&2; exit 1; }
mountpoint -q -- "$SRC" && mountpoint -q -- "$DEST" || { echo "Both source and destination must be mounted; aborting." >&2; exit 1; }
options=(-av --delete --itemize-changes)
if (( ! APPLY )); then options+=(--dry-run); echo "Preview only. Use --apply to execute the mirror, including deletions."; fi
rsync "${options[@]}" -- "$SRC/" "$DEST/"
if (( APPLY )); then echo "Backup completed successfully."; else echo "Preview completed; no files changed."; fi
