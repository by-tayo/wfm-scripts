#!/usr/bin/env bash
#
# Network interface report: interfaces + IPs, default route, DNS servers,
# and active listening ports in one readable dump. Read-only. Useful as a
# first-look diagnostic on an unfamiliar box.
#
# Usage:
#   ./network-interface-report.sh

set -uo pipefail

section() {
    echo ""
    echo "=== $1 ==="
}

if ! command -v ip >/dev/null 2>&1; then
    echo "This script requires 'ip' (package: iproute2)." >&2
    exit 1
fi

section "Interfaces + addresses"
ip -brief address show

section "Default route"
ip route show default

section "Full routing table"
ip route show

section "DNS servers (resolv.conf)"
if [ -f /etc/resolv.conf ]; then
    grep -E '^\s*nameserver' /etc/resolv.conf || echo "(no nameserver lines found)"
else
    echo "/etc/resolv.conf not found"
fi

section "Listening ports"
if command -v ss >/dev/null 2>&1; then
    ss -tulnp 2>/dev/null || ss -tuln
else
    echo "'ss' not found — skipping (package: iproute2)."
fi
