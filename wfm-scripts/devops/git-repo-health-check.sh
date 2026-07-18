#!/usr/bin/env bash
#
# Scans a directory for git repositories and reports which ones have
# uncommitted changes, unpushed commits, or are behind their upstream.
# Read-only — runs `git status`/`git fetch --dry-run` style checks only,
# never modifies a repo.
#
# Usage:
#   ./git-repo-health-check.sh [root-path]
#
# Examples:
#   ./git-repo-health-check.sh                 # scan $HOME
#   ./git-repo-health-check.sh ~/projects       # scan a specific directory

set -uo pipefail

ROOT="${1:-$HOME}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -d "$ROOT" ]; then
    echo "No such directory: $ROOT" >&2
    exit 1
fi

echo "Scanning for git repositories under $ROOT ..."
echo ""

FOUND=0

while IFS= read -r -d '' gitdir; do
    repo="$(dirname "$gitdir")"
    FOUND=$((FOUND + 1))

    cd "$repo" || continue

    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
    dirty=$(git status --porcelain 2>/dev/null)

    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
    ahead_behind=""
    if [ -n "$upstream" ]; then
        counts=$(git rev-list --left-right --count "HEAD...@{u}" 2>/dev/null || echo "0 0")
        ahead=$(echo "$counts" | awk '{print $1}')
        behind=$(echo "$counts" | awk '{print $2}')
        [ "$ahead" != "0" ] && ahead_behind="${ahead_behind} ${ahead} ahead"
        [ "$behind" != "0" ] && ahead_behind="${ahead_behind} ${behind} behind"
    fi

    status_bits=()
    [ -n "$dirty" ] && status_bits+=("uncommitted changes")
    [ -n "$ahead_behind" ] && status_bits+=("$(echo "$ahead_behind" | xargs)")
    [ -z "$upstream" ] && status_bits+=("no upstream")

    if [ "${#status_bits[@]}" -eq 0 ]; then
        echo -e "${GREEN}clean${NC}  $repo  (${branch})"
    else
        joined=$(printf '%s, ' "${status_bits[@]}")
        joined="${joined%, }"
        echo -e "${YELLOW}${joined}${NC}  $repo  (${branch})"
    fi
done < <(find "$ROOT" -type d -name ".git" -prune -print0 2>/dev/null)

echo ""
if [ "$FOUND" -eq 0 ]; then
    echo "No git repositories found under $ROOT."
else
    echo "Scanned $FOUND repositor$( [ "$FOUND" -eq 1 ] && echo y || echo ies )."
fi
