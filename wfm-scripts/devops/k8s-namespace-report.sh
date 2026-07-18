#!/usr/bin/env bash
#
# Read-only snapshot of a Kubernetes namespace: pod status (flagging
# non-Running/high-restart pods), deployments, PVCs, and recent warning
# events. Requires kubectl with an active context. Never modifies cluster
# state.
#
# Usage:
#   ./k8s-namespace-report.sh [namespace]
#
# Examples:
#   ./k8s-namespace-report.sh                # current context's default namespace
#   ./k8s-namespace-report.sh production      # a specific namespace

set -uo pipefail

NAMESPACE="${1:-default}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

section() {
    echo ""
    echo "=== $1 ==="
}

if ! command -v kubectl >/dev/null 2>&1; then
    echo "kubectl not found." >&2
    exit 1
fi

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "Namespace '$NAMESPACE' not found (or no cluster access)." >&2
    exit 1
fi

echo "Context: $(kubectl config current-context 2>/dev/null)"
echo "Namespace: $NAMESPACE"

section "Pods"
kubectl get pods -n "$NAMESPACE" -o wide

section "Pods needing attention (not Running/Completed, or restarting a lot)"
kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | awk '
{
    status=$3; restarts=$4;
    gsub(/[^0-9].*/, "", restarts);
    if (status != "Running" && status != "Completed") flagged=1;
    else if (restarts+0 >= 5) flagged=1;
    else flagged=0;
    if (flagged) print $0;
}' || echo "(none found)"

section "Deployments"
kubectl get deployments -n "$NAMESPACE" -o wide

section "PersistentVolumeClaims"
kubectl get pvc -n "$NAMESPACE"

section "Recent warning events"
kubectl get events -n "$NAMESPACE" --field-selector type=Warning --sort-by='.lastTimestamp' | tail -n 20
