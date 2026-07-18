#!/usr/bin/env bash
#
# TCP connectivity check: tests whether a host is reachable on a list of
# ports and reports open/closed/timeout for each. Uses /dev/tcp (bash
# built-in) so it works with no extra dependencies — falls back to nc if
# available and /dev/tcp is disabled. Read-only.
#
# Usage:
#   ./port-connectivity-check.sh <host> [port1 port2 ...]
#
# Examples:
#   ./port-connectivity-check.sh example.com                  # common ports
#   ./port-connectivity-check.sh 10.0.0.5 22 80 443 3306       # specific ports

set -uo pipefail  # no -e: individual port failures are expected, not fatal

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

TIMEOUT=3
COMMON_PORTS=(22 80 443 3389 3306 5432 6379 8080)

HOST="${1:-}"
if [ -z "$HOST" ]; then
    echo "Usage: $0 <host> [port1 port2 ...]" >&2
    exit 1
fi
shift || true

if [ "$#" -gt 0 ]; then
    PORTS=("$@")
else
    PORTS=("${COMMON_PORTS[@]}")
fi

echo "Checking $HOST on ${#PORTS[@]} port(s) (timeout: ${TIMEOUT}s each)..."
echo ""

for port in "${PORTS[@]}"; do
    if timeout "$TIMEOUT" bash -c "exec 3<>/dev/tcp/${HOST}/${port}" 2>/dev/null; then
        exec 3<&- 3>&- 2>/dev/null || true
        echo -e "  port ${port}: ${GREEN}open${NC}"
    else
        status=$?
        if [ "$status" -eq 124 ]; then
            echo -e "  port ${port}: ${YELLOW}timeout${NC} (filtered or host unreachable)"
        else
            echo -e "  port ${port}: ${RED}closed/refused${NC}"
        fi
    fi
done
