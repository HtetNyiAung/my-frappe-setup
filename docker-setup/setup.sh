#!/usr/bin/env bash

# Purpose: Build custom Docker image and initialize a Frappe site with custom apps
set -e

# --- 1. Manage Submodules ---
echo "Updating git submodules..."
git submodule update --init --recursive

# --- 2. Load Environment Variables ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | sed 's/\s*#.*$//' | xargs)
    echo "Environment variables loaded from .env"
else 
    echo "Error: .env file not found. Setup aborted."; exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Initializing Project: $STACK_ID"
echo "=========================================="

# --- 3. Verify Docker Status ---
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker/WSL2."; exit 1
fi

# --- 4. Manage frappe_docker Repository ---
FRAPPE_PATH="$SCRIPT_DIR/frappe_docker"
if [ ! -d "$FRAPPE_PATH" ]; then
    echo "Cloning frappe_docker dependencies..."
    git clone https://github.com/frappe/frappe_docker.git "$FRAPPE_PATH"
else
    echo "Updating frappe_docker repository..."
    (cd "$FRAPPE_PATH" && git pull)
fi

# --- 5. Build Custom Docker Image ---
echo "Building Image: $CUSTOM_IMAGE"
cp "$SCRIPT_DIR/apps.json" "$FRAPPE_PATH/apps.json"
cd "$FRAPPE_PATH"

# Encode apps.json to Base64 for Docker build context
APPS_JSON_BASE64=$(base64 -w 0 apps.json 2>/dev/null || base64 apps.json | tr -d '\n')

# Build custom image
docker build \
    --build-arg FRAPPE_BRANCH="$FRAPPE_BRANCH" \
    --build-arg APPS_JSON_BASE64="$APPS_JSON_BASE64" \
    --tag "$CUSTOM_IMAGE" \
    --file images/custom/Containerfile .

cd "$SCRIPT_DIR"

# --- 6. Orchestrate Containers ---
echo "Starting containers via $COMPOSE_FILE..."
docker compose -f "$COMPOSE_FILE" up -d
echo "Waiting for services to stabilize (45s)..."
sleep 45

# --- 7. Extract All App Names from apps.json ---
# Improved logic: Extract "name" if present, otherwise extract from "url"
APP_LIST=$(jq -r '.[] | if .name then .name else (.url | split("/") | last) end' apps.json | xargs)
INSTALL_APP_ARGS=""
for app in $APP_LIST; do
    INSTALL_APP_ARGS="${INSTALL_APP_ARGS} --install-app ${app}"
done

# --- 8. Dynamic Site Creation & App Installation ---
echo "Checking site status for domain: $SITE_DOMAIN"

# Wait for backend to be ready
echo "Waiting for backend container to be ready..."
for i in {1..15}; do
    if docker compose exec -T backend bench list-sites >/dev/null 2>&1; then
        echo "Backend is ready!"
        break
    else
        echo "Waiting for backend... ($i/15)"
        sleep 10
    fi
done

# Check if site exists
if docker compose exec -T backend bench list-sites 2>/dev/null | grep -q "$SITE_DOMAIN"; then
    echo "Site $SITE_DOMAIN exists. Installing apps and running migrations..."
    docker compose exec -T backend bench --site "$SITE_DOMAIN" install-app $APP_LIST || true
    docker compose exec -T backend bench --site "$SITE_DOMAIN" migrate
    echo "App installation and migrations completed for existing site!"
else
    echo "Provisioning new site: $SITE_DOMAIN..."
    echo "This may take 5-10 minutes..."
    
    # Create new site with all apps
    docker compose exec -T backend bench new-site "$SITE_DOMAIN" \
        --admin-password "$ADMIN_PASSWORD" \
        --root-login root \
        --root-password "$MYSQL_ROOT_PASSWORD" \
        $INSTALL_APP_ARGS \
        --set-default
    
    # Run migration one last time to be sure
    docker compose exec -T backend bench --site "$SITE_DOMAIN" migrate
    echo "New site created and migrated successfully!"
fi

echo "=========================================="
echo "Setup Complete!"
echo "Frappe URL: http://localhost:$FRAPPE_PORT"
echo "Keycloak URL: http://localhost:$KC_PORT"
echo "Site Domain: $SITE_DOMAIN"
echo "Username: Administrator"
echo "Password: $ADMIN_PASSWORD"
echo "=========================================="
