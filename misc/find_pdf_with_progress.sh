#!/usr/bin/env bash
#This is a Bash script for RHEL that:
#searches all mounted real drives
#skips fake/system filesystems like /proc, /sys, etc.
#looks for Companions Along The Way.pdf
#shows a live progress bar
#prints any matches it finds




set -u

if [[ "${1:-}" == --help || $# -ne 1 ]]; then
    echo "Usage: $0 FILENAME.pdf"
    [[ "${1:-}" == --help ]] && exit 0
    exit 2
fi
needle="$1"
needle_lc="${needle,,}"

# Filesystems to skip
skip_fs_regex='^(proc|sysfs|devtmpfs|devpts|tmpfs|cgroup2?|pstore|securityfs|debugfs|tracefs|configfs|overlay|squashfs|ramfs|hugetlbfs|mqueue|autofs|binfmt_misc|fusectl)$'

# Collect mounted "real" filesystems
mapfile -t mounts < <(
    findmnt -rn -o TARGET,FSTYPE |
    awk -v re="$skip_fs_regex" '$2 !~ re { print $1 }' |
    sort -u
)

if [ "${#mounts[@]}" -eq 0 ]; then
    echo "No searchable mounted drives found."
    exit 1
fi

echo "Searching these mount points:"
printf '  %s\n' "${mounts[@]}"
echo

# Count directories first so we can show progress
echo "Counting directories first for progress bar..."
total_dirs=0
for mnt in "${mounts[@]}"; do
    count=$(find "$mnt" -xdev -type d 2>/dev/null | wc -l)
    total_dirs=$(( total_dirs + count ))
done

if [ "$total_dirs" -eq 0 ]; then
    echo "No directories found to scan."
    exit 1
fi

draw_progress() {
    local current=$1
    local total=$2
    local width=40
    local percent=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    printf '\rProgress: ['
    printf '%0.s#' $(seq 1 "$filled")
    printf '%0.s-' $(seq 1 "$empty")
    printf '] %3d%% (%d/%d dirs)' "$percent" "$current" "$total"
}

echo "Searching..."
scanned_dirs=0
found=0

while IFS= read -r -d '' path; do
    if [ -d "$path" ]; then
        scanned_dirs=$(( scanned_dirs + 1 ))
        draw_progress "$scanned_dirs" "$total_dirs"
    elif [ -f "$path" ]; then
        base="${path##*/}"
        if [ "${base,,}" = "$needle_lc" ]; then
            printf '\nMATCH: %s\n' "$path"
            found=1
        fi
    fi
done < <(
    find "${mounts[@]}" -xdev \( -type d -o -type f \) -print0 2>/dev/null
)

draw_progress "$total_dirs" "$total_dirs"
echo

if [ "$found" -eq 0 ]; then
    echo "No match found for: $needle"
fi

