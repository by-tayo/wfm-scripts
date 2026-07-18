#!/usr/bin/env bash
#
# Deletes log files older than N days under a given path. Defaults to a
# dry run (report only) — nothing is deleted unless you pass --execute.
#
# Usage:
#   ./log-cleanup.sh [--path /var/log] [--days 30] [--pattern '*.log'] [--execute]
#
# Examples:
#   ./log-cleanup.sh                                  # dry run, /var/log, 30 days, *.log
#   ./log-cleanup.sh --days 14 --execute               # actually delete logs older than 14 days
#   ./log-cleanup.sh --path /var/log/myapp --pattern '*.log.gz' --execute

set -euo pipefail

LOG_PATH="/var/log"
DAYS=30
PATTERN="*.log"
EXECUTE=false

while [ $# -gt 0 ]; do
    case "$1" in
        --path) LOG_PATH="$2"; shift 2 ;;
        --days) DAYS="$2"; shift 2 ;;
        --pattern) PATTERN="$2"; shift 2 ;;
        --execute) EXECUTE=true; shift ;;
        *) echo "Unknown flag: $1" >&2; exit 1 ;;
    esac
done

if [ ! -d "$LOG_PATH" ]; then
    echo "No such directory: $LOG_PATH" >&2
    exit 1
fi

MATCHES=$(find "$LOG_PATH" -type f -name "$PATTERN" -mtime "+${DAYS}" 2>/dev/null || true)

if [ -z "$MATCHES" ]; then
    echo "No files matching '$PATTERN' older than $DAYS days under $LOG_PATH."
    exit 0
fi

COUNT=$(echo "$MATCHES" | wc -l)
TOTAL_SIZE=$(echo "$MATCHES" | xargs -d '\n' du -ch 2>/dev/null | tail -n1 | cut -f1)

echo "Found $COUNT file(s) matching '$PATTERN' older than $DAYS days under $LOG_PATH (total: $TOTAL_SIZE):"
echo "$MATCHES"

if [ "$EXECUTE" = false ]; then
    echo ""
    echo "Dry run — nothing deleted. Re-run with --execute to actually delete these files."
    exit 0
fi

echo ""
read -p "Delete all $COUNT file(s) listed above? Type 'yes' to continue: " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted — nothing deleted."
    exit 0
fi

echo "$MATCHES" | xargs -d '\n' rm -f --
echo "Deleted $COUNT file(s)."
