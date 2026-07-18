#!/usr/bin/env bash
#
# Disk usage report: filesystem summary + top N largest directories under a
# given path. Read-only — doesn't modify or delete anything.
#
# Usage:
#   ./disk-usage-report.sh [path] [top-n]
#
# Examples:
#   ./disk-usage-report.sh                # report on / , top 15 dirs
#   ./disk-usage-report.sh /var 20         # report on /var, top 20 dirs

set -euo pipefail

TARGET_PATH="${1:-/}"
TOP_N="${2:-15}"

section() {
    echo ""
    echo "=== $1 ==="
}

if [ ! -d "$TARGET_PATH" ]; then
    echo "No such directory: $TARGET_PATH" >&2
    exit 1
fi

section "Filesystem summary"
df -h

section "Top $TOP_N largest directories under $TARGET_PATH"
# du can hit permission-denied on system dirs when not run as root — that's
# expected and fine, stderr is discarded so the report stays readable.
du -x -h --max-depth=2 "$TARGET_PATH" 2>/dev/null | sort -rh | head -n "$TOP_N"

section "Largest individual files under $TARGET_PATH (top $TOP_N)"
find "$TARGET_PATH" -xdev -type f -printf '%s %p\n' 2>/dev/null |
    sort -rn | head -n "$TOP_N" |
    awk '{ size=$1; $1=""; printf "%10.1f MB  %s\n", size/1024/1024, $0 }'

section "Done"
