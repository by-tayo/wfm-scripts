#!/usr/bin/env bash
#
# Systemd service health check: reports failed units, plus the status of an
# optional explicit list of services you care about. Read-only.
#
# Usage:
#   ./service-health-check.sh [service1 service2 ...]
#
# Examples:
#   ./service-health-check.sh                          # just failed units
#   ./service-health-check.sh nginx docker sshd         # + these specifically

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

section() {
    echo ""
    echo "=== $1 ==="
}

if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl not found — this script requires a systemd-based system." >&2
    exit 1
fi

section "Failed units"
FAILED=$(systemctl --failed --no-legend --plain)
if [ -z "$FAILED" ]; then
    echo -e "${GREEN}No failed units.${NC}"
else
    echo -e "${RED}$FAILED${NC}"
fi

if [ "$#" -gt 0 ]; then
    section "Requested services"
    for svc in "$@"; do
        if ! systemctl list-unit-files "${svc}.service" --no-legend >/dev/null 2>&1; then
            echo -e "${YELLOW}${svc}: unit not found${NC}"
            continue
        fi
        STATE=$(systemctl is-active "$svc" 2>/dev/null || true)
        ENABLED=$(systemctl is-enabled "$svc" 2>/dev/null || echo "unknown")
        case "$STATE" in
            active) COLOR="$GREEN" ;;
            *)      COLOR="$RED" ;;
        esac
        echo -e "${svc}: ${COLOR}${STATE}${NC} (enabled: ${ENABLED})"
    done
fi

section "Done"
