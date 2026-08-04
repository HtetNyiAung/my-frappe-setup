#!/usr/bin/env bash
# Purpose: Dynamic, real-time monitoring of all container logs in the stack (Frappe, Authentik, etc.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
# Record lifecycle only; duplicating a continuous Docker log stream can fill disk.
init_script_logging "$SCRIPT_DIR" "logs" "metadata"

# --- 1. Load Environment Variables ---
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a
else 
    echo "❌ Error: .env file missing."; exit 1
fi

apply_script_log_retention "${SCRIPT_LOG_RETENTION_DAYS:-30}"

STACK_ID=${STACK_ID:-frappe_stack}
echo "=========================================="
echo "Streaming Logs: $STACK_ID"
echo "Press Ctrl+C to stop."
echo "=========================================="

# Build command based on existing compose files
COMPOSE_FILES=("-f" "$COMPOSE_FILE")
[ -f docker-compose.override.yml ] && COMPOSE_FILES+=("-f" "docker-compose.override.yml")
[ -f docker-compose.authentik.yml ] && COMPOSE_FILES+=("-f" "docker-compose.authentik.yml")
[ -f docker-compose.keycloak.yml ] && COMPOSE_FILES+=("-f" "docker-compose.keycloak.yml")

# Use -f to follow and --tail to avoid initial noise
docker compose "${COMPOSE_FILES[@]}" logs -f --tail 100
