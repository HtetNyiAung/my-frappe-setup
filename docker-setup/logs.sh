#!/usr/bin/env bash
# Purpose: Real-time monitoring of all container logs in the stack

# --- 1. Load Environment Variables ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | sed 's/\s*#.*$//' | xargs)
else 
    echo "Error: .env file missing."; exit 1
fi

echo "=========================================="
echo "Streaming Logs: $STACK_ID"
echo "Press Ctrl+C to stop."
echo "=========================================="

# -f follows the stream, --tail 100 avoids overwhelming the terminal
docker compose -f "$COMPOSE_FILE" -f docker-compose.keycloak.yml logs -f --tail 100