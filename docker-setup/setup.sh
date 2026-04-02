#!/usr/bin/env bash

# Purpose: Fully automated stack build with selective custom app mounting
# NOTE: We intentionally do NOT use 'set -e' so that individual app failures
# don't kill the entire setup. Critical steps check errors explicitly.

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
        if ! git clone --branch "$BRANCH" "$URL" "$TARGET_DIR"; then
            echo "⚠️  Warning: Failed to clone $NAME. Skipping volume mount."
            continue
        fi
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
    # Safety Backup before rebuild if site exists
    if [ "$FORCE_REBUILD" = true ] && [ -f "./backup.sh" ]; then
        echo "Rebuilding image... Taking a safety backup first..."
        ./backup.sh || echo "Warning: Backup failed, but proceeding with rebuild..."
    fi

    FRAPPE_PATH="$SCRIPT_DIR/frappe_docker"
    if [ ! -d "$FRAPPE_PATH" ]; then
        git clone https://github.com/frappe/frappe_docker.git "$FRAPPE_PATH"
    fi

    cp "$SCRIPT_DIR/apps.json" "$FRAPPE_PATH/apps.json"
    cd "$FRAPPE_PATH"
    APPS_JSON_BASE64=$(base64 -w 0 apps.json 2>/dev/null || base64 apps.json | tr -d '\n')

    echo "Building Image: $CUSTOM_IMAGE"
    if ! docker build \
        --build-arg FRAPPE_BRANCH="$FRAPPE_BRANCH" \
        --build-arg APPS_JSON_BASE64="$APPS_JSON_BASE64" \
        --tag "$CUSTOM_IMAGE" \
        --file images/custom/Containerfile .; then
        echo ""
        echo "❌ ============================================="
        echo "❌  Docker image build FAILED!"
        echo "❌  Check apps.json for invalid branches/URLs."
        echo "❌  Common fix: ensure all app dependencies"
        echo "❌  (like 'payments') are in apps.json with"
        echo "❌  the correct branch."
        echo "❌ ============================================="
        cd "$SCRIPT_DIR"
        exit 1
    fi

    cd "$SCRIPT_DIR"
fi

cd "$SCRIPT_DIR"

# Build dynamic compose command
COMPOSE_CMD=("docker" "compose" "-f" "$COMPOSE_FILE" "-f" "$OVERRIDE_FILE")

echo "Starting containers..."
if ! "${COMPOSE_CMD[@]}" up -d; then
    echo ""
    echo "❌ CRITICAL ERROR: Docker failed to start containers."
    echo "Check if you have internet access or Docker credential issues."
    echo "Common fix: run 'mv ~/.docker/config.json ~/.docker/config.json.bak'"
    exit 1
fi
echo "Waiting for stabilization (45s)..."
sleep 45

# --- 6. Site Creation & App Installation ---
APP_LIST=$(jq -r '.[] | if .name then .name else (.url | split("/") | last | split(".") | first) end' apps.json | xargs)
echo "Apps to install: $APP_LIST"

# Track installation results
INSTALL_OK=()
INSTALL_FAIL=()

# Wait for backend
BACKEND_READY=false
for i in {1..15}; do
    if "${COMPOSE_CMD[@]}" exec -T backend bench list-sites >/dev/null 2>&1; then
        echo "✅ Backend is ready!"
        BACKEND_READY=true
        break
    fi
    echo "Waiting for backend... ($i/15)"
    sleep 10
done

if [ "$BACKEND_READY" = false ]; then
    echo "❌ Backend did not become ready in time. Aborting app installation."
    exit 1
fi

# Run installation/migration
if "${COMPOSE_CMD[@]}" exec -T backend bench list-sites | grep -q "$SITE_DOMAIN"; then
    echo "Site $SITE_DOMAIN exists. Installing/Updating apps one by one..."
    for app in $APP_LIST; do
        [ "$app" = "frappe" ] && continue
        echo ""
        echo "━━━ Installing: $app ━━━"
        if "${COMPOSE_CMD[@]}" exec -T backend bench --site "$SITE_DOMAIN" install-app "$app" 2>&1; then
            echo "✅ $app installed successfully."
            INSTALL_OK+=("$app")
        else
            echo "⚠️  $app failed to install. Continuing with remaining apps..."
            INSTALL_FAIL+=("$app")
        fi
    done
    echo ""
    echo "Running migrate..."
    "${COMPOSE_CMD[@]}" exec -T backend bench --site "$SITE_DOMAIN" migrate || echo "⚠️  Migration had warnings/errors."
else
    echo "Creating new site: $SITE_DOMAIN..."
    if ! "${COMPOSE_CMD[@]}" exec -T backend bench new-site "$SITE_DOMAIN" \
        --admin-password "$ADMIN_PASSWORD" --root-login root --root-password "$MYSQL_ROOT_PASSWORD" --set-default; then
        echo "❌ Failed to create site $SITE_DOMAIN. Aborting."
        exit 1
    fi

    echo "Installing apps to new site one by one..."
    for app in $APP_LIST; do
        [ "$app" = "frappe" ] && continue
        echo ""
        echo "━━━ Installing: $app ━━━"
        if "${COMPOSE_CMD[@]}" exec -T backend bench --site "$SITE_DOMAIN" install-app "$app" 2>&1; then
            echo "✅ $app installed successfully."
            INSTALL_OK+=("$app")
        else
            echo "⚠️  $app failed to install. Continuing with remaining apps..."
            INSTALL_FAIL+=("$app")
        fi
    done
fi

# --- 7. Summary ---
echo ""
echo "══════════════════════════════════════════"
echo "  Setup Complete! Site: $SITE_DOMAIN"
echo "══════════════════════════════════════════"
if [ ${#INSTALL_OK[@]} -gt 0 ]; then
    echo "  ✅ Installed: ${INSTALL_OK[*]}"
fi
if [ ${#INSTALL_FAIL[@]} -gt 0 ]; then
    echo "  ⚠️  Failed:    ${INSTALL_FAIL[*]}"
    echo ""
    echo "  To retry failed apps, run:"
    for fail_app in "${INSTALL_FAIL[@]}"; do
        echo "    docker compose exec backend bench --site $SITE_DOMAIN install-app $fail_app"
    done
fi
echo ""
echo "Currently installed apps:"
"${COMPOSE_CMD[@]}" exec -T backend bench --site "$SITE_DOMAIN" list-apps || true
