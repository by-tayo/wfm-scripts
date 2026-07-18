#!/usr/bin/env bash
#
# Reports (and optionally removes) stopped containers, dangling images, and
# unused volumes/networks. Defaults to a dry run — nothing is removed unless
# you pass --execute.
#
# Usage:
#   ./docker-cleanup.sh [--execute] [--include-volumes]
#
# Examples:
#   ./docker-cleanup.sh                         # dry run: report only
#   ./docker-cleanup.sh --execute                # actually clean containers/images/networks
#   ./docker-cleanup.sh --execute --include-volumes   # also remove unused volumes (data loss risk)

set -euo pipefail

EXECUTE=false
INCLUDE_VOLUMES=false

while [ $# -gt 0 ]; do
    case "$1" in
        --execute) EXECUTE=true; shift ;;
        --include-volumes) INCLUDE_VOLUMES=true; shift ;;
        *) echo "Unknown flag: $1" >&2; exit 1 ;;
    esac
done

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker not found." >&2
    exit 1
fi

section() {
    echo ""
    echo "=== $1 ==="
}

section "Stopped containers"
docker ps -a --filter status=exited --filter status=created \
    --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'

section "Dangling images"
docker images --filter dangling=true --format 'table {{.ID}}\t{{.Repository}}\t{{.Size}}'

section "Unused networks"
docker network ls --filter dangling=true --format 'table {{.ID}}\t{{.Name}}\t{{.Driver}}'

if [ "$INCLUDE_VOLUMES" = true ]; then
    section "Unused volumes"
    docker volume ls --filter dangling=true --format 'table {{.Name}}\t{{.Driver}}'
fi

if [ "$EXECUTE" = false ]; then
    section "Dry run"
    echo "Nothing removed. Re-run with --execute to actually clean up the items listed above."
    exit 0
fi

section "Cleaning up"
docker container prune -f
docker image prune -f
docker network prune -f
if [ "$INCLUDE_VOLUMES" = true ]; then
    echo "Pruning volumes too — this can delete data from containers that are still expected to use them."
    docker volume prune -f
fi

section "Done"
docker system df
