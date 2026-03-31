#!/usr/bin/env bash

# Purpose: Fully automated stack build with selective custom app mounting
set -e

# --- 1. Load Environment Variables ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | sed 's/\s*#.*$//' | xargs)
    echo "Environment variables loaded from .env"
else 
    echo "Error: .env file not found. Setup aborted."; exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- 2. Auto-Clone & Generate Volume Overrides (Selective Logic) ---
echo "Checking apps from apps.json for custom development apps..."
mkdir -p ../apps

# --- 2. Fix Directory Permissions for Authentik (Local Dev Only) ---
echo "Configuring permissions for local volume folders..."
mkdir -p ./authentik_media ./authentik_certs ./authentik_custom_templates
chmod -R 777 ./authentik_media ./authentik_certs ./authentik_custom_templates 2>/dev/null || true

OVERRIDE_FILE="docker-compose.override.yml"
echo "services:" > $OVERRIDE_FILE
SERVICES=("backend" "configurator" "create-site" "queue-long" "queue-short" "scheduler" "websocket")

# Parse apps.json for only 'is_custom: true' apps
CUSTOM_APPS=$(jq -c '.[] | select(.is_custom == true)' apps.json)
for row in $CUSTOM_APPS; do
    NAME=$(echo ${row} | jq -r '.name // (.url | split("/") | last | split(".") | first)')
    URL=$(echo ${row} | jq -r '.url')
    BRANCH=$(echo ${row} | jq -r '.branch // "main"')
    
    TARGET_DIR="../apps/$NAME"
    
    # 1. Clone only if missing on host
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Found new custom app: $NAME ($URL). Cloning to host..."
        git clone --branch "$BRANCH" "$URL" "$TARGET_DIR"
    else
        echo "Custom app $NAME exists on host."
    fi

    # 2. Dynamically add volume mounts to the override file for each core service
    echo "  Configuring volume mount for: $NAME"
    for svc in "${SERVICES[@]}"; do
        if ! grep -q "$svc:" $OVERRIDE_FILE; then
            echo "  $svc:" >> $OVERRIDE_FILE
            echo "    volumes:" >> $OVERRIDE_FILE
        fi
        echo "      - ../apps/$NAME:/home/frappe/frappe-bench/apps/$NAME" >> $OVERRIDE_FILE
    done
done

# --- 3. Manage Submodules ---
echo "Updating git submodules (if any)..."
git submodule update --init --recursive 2>/dev/null || true

# --- 4. Build Custom Docker Image (All apps included) ---
# Skip build if image already exists (use ./setup.sh --rebuild to force)
FORCE_REBUILD=false
if [[ "${1:-}" == "--rebuild" ]]; then
    FORCE_REBUILD=true
fi

if docker image inspect "$CUSTOM_IMAGE" >/dev/null 2>&1 && [ "$FORCE_REBUILD" = false ]; then
    echo "Image '$CUSTOM_IMAGE' already exists. Skipping build. (Use --rebuild to force)"
else
    FRAPPE_PATH="$SCRIPT_DIR/frappe_docker"
    if [ ! -d "$FRAPPE_PATH" ]; then
        git clone https://github.com/frappe/frappe_docker.git "$FRAPPE_PATH"
    fi

    cp "$SCRIPT_DIR/apps.json" "$FRAPPE_PATH/apps.json"
    cd "$FRAPPE_PATH"
    APPS_JSON_BASE64=$(base64 -w 0 apps.json 2>/dev/null || base64 apps.json | tr -d '\n')

    echo "Building Image: $CUSTOM_IMAGE"
    docker build \
        --build-arg FRAPPE_BRANCH="$FRAPPE_BRANCH" \
        --build-arg APPS_JSON_BASE64="$APPS_JSON_BASE64" \
        --tag "$CUSTOM_IMAGE" \
        --file images/custom/Containerfile .

    cd "$SCRIPT_DIR"
fi

cd "$SCRIPT_DIR"

# Build dynamic compose command
COMPOSE_CMD=("docker" "compose" "-f" "$COMPOSE_FILE" "-f" "$OVERRIDE_FILE")

echo "Starting containers..."
"${COMPOSE_CMD[@]}" up -d
echo "Waiting for stabilization (45s)..."
# "${COMPOSE_CMD[@]}" logs -f --tail 50 authentik-server & # Show brief logs to see progress
# SERVER_PID=$!
sleep 45
# kill $SERVER_PID 2>/dev/null || true

# --- 6. Site Creation & App Installation ---
APP_LIST=$(jq -r '.[] | if .name then .name else (.url | split("/") | last | split(".") | first) end' apps.json | xargs)
echo "Installing apps to site: $APP_LIST"

# Wait for backend
for i in {1..15}; do
    if "${COMPOSE_CMD[@]}" exec -T backend bench list-sites >/dev/null 2>&1; then
        echo "Backend is ready!"
        break
    fi
    echo "Waiting for backend... ($i/15)"
    sleep 10
done

# Run installation/migration via the override context
if "${COMPOSE_CMD[@]}" exec -T backend bench list-sites | grep -q "$SITE_DOMAIN"; then
    "${COMPOSE_CMD[@]}" exec -T backend bench --site "$SITE_DOMAIN" install-app $APP_LIST || true
    "${COMPOSE_CMD[@]}" exec -T backend bench --site "$SITE_DOMAIN" migrate
else
    # new-site logic...
    INSTALL_ARGS=""
    for app in $APP_LIST; do INSTALL_ARGS="${INSTALL_ARGS} --install-app ${app}"; done
    "${COMPOSE_CMD[@]}" exec -T backend bench new-site "$SITE_DOMAIN" \
        --admin-password "$ADMIN_PASSWORD" --root-login root --root-password "$MYSQL_ROOT_PASSWORD" \
        $INSTALL_ARGS --set-default
fi

echo "Setup Complete!"
