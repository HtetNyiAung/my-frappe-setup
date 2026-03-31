#!/usr/bin/env bash
# Purpose: Deep clean containers, volumes, and images specifically for the Frappe/Authentik/Keycloak project.
# WARNING: All local data, database records, and custom configurations will be permanently removed.
set -e

# --- 1. Load Environment Variables ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | sed 's/\s*#.*$//' | xargs)
else 
    echo "❌ Error: .env file missing. Cleanup aborted."
    exit 1
fi

STACK_ID=${STACK_ID:-frappe_stack}
echo "=========================================="
echo "⚠️  DANGER: FULL SYSTEM RESET - $STACK_ID"
echo "=========================================="

# Collect all possible compose files
COMPOSE_FILES=("-f" "$COMPOSE_FILE")
[ -f docker-compose.override.yml ] && COMPOSE_FILES+=("-f" "docker-compose.override.yml")
[ -f docker-compose.authentik.yml ] && COMPOSE_FILES+=("-f" "docker-compose.authentik.yml")
[ -f docker-compose.keycloak.yml ] && COMPOSE_FILES+=("-f" "docker-compose.keycloak.yml")

# --- 2. Stop Containers and Wipe Volumes ---
echo "🛑 Stopping containers and wiping volumes for project: $STACK_ID..."
docker compose "${COMPOSE_FILES[@]}" down -v --remove-orphans

# --- 3. Delete Custom Project Images ---
IMAGE_BASE_NAME=$(echo "$CUSTOM_IMAGE" | cut -d':' -f1)
if [ -n "$IMAGE_BASE_NAME" ]; then
    echo "🗑️ Deleting custom image: $IMAGE_BASE_NAME"
    docker images -q "$IMAGE_BASE_NAME" | xargs -r docker rmi -f || true
fi

# --- 4. Extra Cleanup for Authentik/Local Dirs ---
# Resetting permissions/media for a clean start next time
echo "🧹 Cleaning up local volume folders..."
sudo rm -rf ./authentik_media/* ./authentik_certs/* 2>/dev/null || true
mkdir -p ./authentik_media ./authentik_certs ./authentik_custom_templates
chmod -R 777 ./authentik_media ./authentik_certs ./authentik_custom_templates 2>/dev/null || true

# --- 5. Pruning (Project Specific) ---
echo "🧹 Pruning project-specific build cache and dangling images..."
docker builder prune -f --filter "label=com.docker.compose.project=$STACK_ID" || true
docker image prune -f

# --- 6. Network Cleanup ---
echo "🌐 Cleaning up leftover networks..."
docker network prune -f --filter "label=com.docker.compose.project=$STACK_ID" || true

echo "=========================================="
echo "✅ Cleanup Finished. $STACK_ID is 100% fresh."
echo "=========================================="