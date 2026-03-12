#!/usr/bin/env bash
# Purpose: Build custom Docker image and initialize the Frappe site
set -e

# --- 1. Load Environment Variables ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | xargs)
else 
    echo "Error: .env file not found. Setup aborted."; exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Initializing Project: $STACK_ID"
echo "=========================================="

# --- 2. Verify Docker Status ---
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker/WSL2."; exit 1
fi

# --- 3. Manage frappe_docker Repository ---
FRAPPE_PATH="$SCRIPT_DIR/frappe_docker"
if [ ! -d "$FRAPPE_PATH" ]; then
    echo "Cloning frappe_docker dependencies..."
    git clone https://github.com/frappe/frappe_docker.git "$FRAPPE_PATH"
else
    echo "Updating frappe_docker repository..."
    (cd "$FRAPPE_PATH" && git pull)
fi

# --- 4. Build Custom Docker Image ---
echo "Building Image: $CUSTOM_IMAGE"
cp "$SCRIPT_DIR/apps.json" "$FRAPPE_PATH/apps.json"
cd "$FRAPPE_PATH"

# Encode apps.json to Base64 for the Docker build context
APPS_JSON_BASE64=$(base64 -w 0 apps.json 2>/dev/null || base64 apps.json | tr -d '\n')

# Build using Python 3.11 for Frappe v16 compatibility
docker build \
    --build-arg FRAPPE_BRANCH="$FRAPPE_BRANCH" \
    --build-arg APPS_JSON_BASE64="$APPS_JSON_BASE64" \
    --tag "$CUSTOM_IMAGE" \
    --file images/custom/Containerfile .

cd "$SCRIPT_DIR"

# --- 5. Orchestrate Containers ---
echo "Starting containers via $COMPOSE_FILE..."
docker compose -f "$COMPOSE_FILE" up -d
echo "Waiting for services to stabilize (45s)..."
sleep 45

# --- 6. Bench Site Logic ---

if docker exec "$BACKEND_CONTAINER" bench list-sites | grep -q "$SITE_DOMAIN"; then
    echo "Site $SITE_DOMAIN exists. Running migrations..."
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" install-app erpnext hrms insights || true
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" migrate
else
    echo "Provisioning new site: $SITE_DOMAIN..."
    docker exec -i "$BACKEND_CONTAINER" bench new-site "$SITE_DOMAIN" \
      --admin-password admin --root-login root --root-password admin \
      --install-app erpnext --install-app hrms --install-app insights --set-default
fi

echo "=========================================="
echo "Setup Complete. Access URL: http://localhost:8080"
echo "=========================================="