#!/usr/bin/env bash
#
# DNS resolution report: looks up a domain (A, AAAA, MX, TXT, NS) against
# several major public resolvers side by side — useful for spotting
# propagation lag or a misconfigured record. Requires `dig`. Read-only.
#
# Usage:
#   ./dns-lookup-report.sh <domain> [record-type]
#
# Examples:
#   ./dns-lookup-report.sh example.com          # A record, all resolvers
#   ./dns-lookup-report.sh example.com MX        # MX record, all resolvers

set -uo pipefail

DOMAIN="${1:-}"
RECORD_TYPE="${2:-A}"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain> [record-type]" >&2
    exit 1
fi

if ! command -v dig >/dev/null 2>&1; then
    echo "This script requires 'dig' (package: dnsutils / bind-utils)." >&2
    exit 1
fi

declare -A RESOLVERS=(
    [System-default]=""
    [Google]="8.8.8.8"
    [Cloudflare]="1.1.1.1"
    [Quad9]="9.9.9.9"
)

echo "Resolving $DOMAIN ($RECORD_TYPE) against multiple resolvers..."
echo ""

for name in "${!RESOLVERS[@]}"; do
    server="${RESOLVERS[$name]}"
    if [ -n "$server" ]; then
        result=$(dig +short "@${server}" "$DOMAIN" "$RECORD_TYPE" 2>/dev/null)
        label="$name (${server})"
    else
        result=$(dig +short "$DOMAIN" "$RECORD_TYPE" 2>/dev/null)
        label="$name"
    fi

    printf "%-24s " "$label"
    if [ -z "$result" ]; then
        echo "(no answer)"
    else
        echo "$result" | tr '\n' ' '
        echo ""
    fi
done

echo ""
echo "Authoritative nameservers:"
dig +short NS "$DOMAIN"
