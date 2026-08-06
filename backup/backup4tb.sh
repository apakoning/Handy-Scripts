#!/bin/bash

SRC="/mnt/HDD4TB/"
DEST="/mnt/Backup4TB/"

# Check if backup drive is mounted
if mountpoint -q /mnt/Backup4TB; then
    echo "Starting backup..."
    rsync -av --delete "$SRC/" "$DEST/"
    echo "✅ Backup completed successfully."
else
    echo "❌ Backup drive not mounted. Aborting."
    exit 1
fi

