#!/usr/bin/env bash
# Purpose: Dynamic, real-time monitoring of all container logs in the stack (Frappe, Authentik, etc.)

# --- 1. Load Environment Variables ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | sed 's/\s*#.*$//' | xargs)
else 
    echo "❌ Error: .env file missing."; exit 1
fi

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