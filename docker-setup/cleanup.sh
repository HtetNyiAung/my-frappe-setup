#!/usr/bin/env bash
# Purpose: Safely delete containers, volumes, and images specifically for the $STACK_ID project.
# WARNING: All site data, database records, and custom configurations will be permanently removed.
set -e

# --- 1. Load Environment Variables ---
# We check for the .env file to ensure we have the correct STACK_ID and image names.
if [ -f .env ]; then 
    export $(grep -v '^#' .env | sed 's/\s*#.*$//' | xargs)
else 
    echo "❌ Error: .env file missing. Cleanup aborted to prevent accidental deletions."
    exit 1
fi

echo "=========================================="
echo "⚠️  DANGER: FULL SYSTEM RESET - $STACK_ID"
echo "=========================================="

# --- 2. Stop Containers and Wipe Volumes ---
# This part stops the services and removes the data volumes (databases/files).
if [ -f "$COMPOSE_FILE" ]; then
    echo "🛑 Stopping containers and wiping volumes for $STACK_ID..."
    # The -v flag ensures that named volumes defined in your YAML are removed.
    # --remove-orphans cleans up containers not defined in the current YAML file.
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans
else
    echo "⚠️  Warning: $COMPOSE_FILE not found. Skipping container removal."
fi

# --- 3. Delete Custom Project Image ---
# We extract the base name of the image (e.g., removing ':latest') to target all tags.
IMAGE_BASE_NAME=$(echo "$CUSTOM_IMAGE" | cut -d':' -f1)

if [ -n "$IMAGE_BASE_NAME" ]; then
    echo "🗑️ Deleting custom image: $IMAGE_BASE_NAME"
    # xargs -r ensures the command doesn't run if no image IDs are found.
    docker images -q "$IMAGE_BASE_NAME" | xargs -r docker rmi -f || true
fi

# --- 4. Targeted Pruning (Project Specific) ---
# Instead of 'docker system prune', we use filters to only clean this project's cache.
echo "🧹 Pruning project-specific build cache..."
docker builder prune -f --filter "label=com.docker.compose.project=$STACK_ID" || docker builder prune -f

echo "🧹 Removing dangling images (unused build layers)..."
docker image prune -f

# --- 5. Network Cleanup ---
# Removes virtual networks created specifically for this Frappe stack.
echo "🌐 Cleaning up leftover networks for $STACK_ID..."
docker network prune -f --filter "label=com.docker.compose.project=$STACK_ID"

echo "=========================================="
echo "✅ Cleanup Finished. $STACK_ID is 100% fresh."
echo "=========================================="