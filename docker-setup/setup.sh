#!/usr/bin/env bash

# Purpose: Fully automated stack build with selective custom app mounting
# NOTE: We intentionally do NOT use 'set -e' so that individual app failures
# don't kill the entire setup. Critical steps check errors explicitly.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "$SCRIPT_DIR"

# --- 1. Load Environment Variables ---
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        echo "No .env found. Copying from .env.example..."
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    else
        echo "Error: Neither .env nor .env.example found. Setup aborted."
        exit 1
    fi
fi
export $(grep -v '^#' "$SCRIPT_DIR/.env" | sed 's/\s*#.*$//' | xargs)
echo "Environment variables loaded from .env"

# --- 2. Prepare frappe_docker correctly ---
FRAPPE_PATH="$SCRIPT_DIR/frappe_docker"

if [ ! -f "$FRAPPE_PATH/images/custom/Containerfile" ]; then
    echo "frappe_docker missing or incomplete. Cloning fresh..."
    rm -rf "$FRAPPE_PATH"
    git clone https://github.com/frappe/frappe_docker.git "$FRAPPE_PATH"

    if [ ! -f "$FRAPPE_PATH/images/custom/Containerfile" ]; then
        echo "❌ Failed to clone frappe_docker correctly."
        exit 1
    fi
else
    echo "frappe_docker exists and is valid."
fi

CUSTOM_APPS_DIR="$FRAPPE_PATH/apps"
mkdir -p "$CUSTOM_APPS_DIR"

# --- 3. Auto-Clone & Generate Volume Overrides ---
echo "Checking apps from apps.json for custom development apps..."

OVERRIDE_FILE="$SCRIPT_DIR/docker-compose.override.yml"

SERVICES=("backend" "configurator" "create-site" "queue-long" "queue-short" "scheduler" "websocket")

# Collect custom app names that are valid (cloned successfully)
VALID_CUSTOM_APPS=()

CUSTOM_APPS=$(jq -c '.[] | select(.is_custom == true)' "$SCRIPT_DIR/apps.json")

for row in $CUSTOM_APPS; do
    NAME=$(echo "$row" | jq -r '.name // (.url | split("/") | last | split(".") | first)')
    URL=$(echo "$row" | jq -r '.url')
    BRANCH=$(echo "$row" | jq -r '.branch // "main"')

    TARGET_DIR="$CUSTOM_APPS_DIR/$NAME"

    if [ ! -d "$TARGET_DIR" ]; then
        echo "Found new custom app: $NAME ($URL). Cloning..."
        if ! git clone --branch "$BRANCH" "$URL" "$TARGET_DIR"; then
            echo "⚠️  Warning: Failed to clone $NAME. Skipping volume mount."
            continue
        fi
    else
        echo "Custom app $NAME exists on host."
    fi

    VALID_CUSTOM_APPS+=("$NAME")
done

# Generate the override file with all custom app volumes per service
echo "services:" > "$OVERRIDE_FILE"

if [ ${#VALID_CUSTOM_APPS[@]} -gt 0 ]; then
    for svc in "backend" "configurator" "create-site" "queue-long" "queue-short" "scheduler" "websocket"; do
        echo "  $svc:" >> "$OVERRIDE_FILE"
        echo "    volumes:" >> "$OVERRIDE_FILE"
        for app_name in "${VALID_CUSTOM_APPS[@]}"; do
            echo "      - ./frappe_docker/apps/$app_name:/home/frappe/frappe-bench/apps/$app_name" >> "$OVERRIDE_FILE"
        done
        echo "✅ Configured $svc with ${#VALID_CUSTOM_APPS[@]} custom apps"
    done
fi

# --- 4. Manage Submodules ---
echo "Updating git submodules (if any)..."
git submodule update --init --recursive 2>/dev/null || true

# --- 5. Build Custom Docker Image ---
FORCE_REBUILD=false
if [[ "${1:-}" == "--rebuild" ]]; then
    FORCE_REBUILD=true
fi

if docker image inspect "$CUSTOM_IMAGE" >/dev/null 2>&1 && [ "$FORCE_REBUILD" = false ]; then
    echo "Image '$CUSTOM_IMAGE' already exists. Skipping build. (Use --rebuild to force)"
else
    if [ "$FORCE_REBUILD" = true ] && [ -f "$SCRIPT_DIR/backup.sh" ]; then
        echo "Rebuilding image... Taking a safety backup first..."
        "$SCRIPT_DIR/backup.sh" || echo "Warning: Backup failed, but proceeding with rebuild..."
    fi

    cp "$SCRIPT_DIR/apps.json" "$FRAPPE_PATH/apps.json"

    cd "$FRAPPE_PATH" || exit 1

    APPS_JSON_BASE64=$(base64 -w 0 apps.json 2>/dev/null || base64 apps.json | tr -d '\n')

    echo "Building Image: $CUSTOM_IMAGE"

    if ! docker build \
        --build-arg FRAPPE_BRANCH="$FRAPPE_BRANCH" \
        --build-arg CACHE_BUST=$(date +%s) \
        --secret id=apps_json,src=apps.json \
        --tag "$CUSTOM_IMAGE" \
        --file images/custom/Containerfile .; then

        echo ""
        echo "❌ ============================================="
        echo "❌  Docker image build FAILED!"
        echo "❌  Check apps.json for invalid branches/URLs."
        echo "❌  Common fix: ensure all app dependencies"
        echo "❌  are in apps.json with correct branch."
        echo "❌ ============================================="

        cd "$SCRIPT_DIR" || exit 1
        exit 1
    fi

    cd "$SCRIPT_DIR" || exit 1
fi

# --- 6. Start Containers ---
cd "$SCRIPT_DIR" || exit 1

COMPOSE_CMD=("docker" "compose" "-f" "$COMPOSE_FILE" "-f" "$OVERRIDE_FILE")

echo "Starting containers..."

if ! "${COMPOSE_CMD[@]}" up -d; then
    echo ""
    echo "❌ CRITICAL ERROR: Docker failed to start containers."
    echo "Check internet access or Docker credential issues."
    echo "Common fix: mv ~/.docker/config.json ~/.docker/config.json.bak"
    exit 1
fi

echo "Waiting for stabilization (45s)..."
sleep 45

# --- 7. Site Creation & App Installation ---
APP_LIST=$(jq -r '.[] | if .name then .name else (.url | split("/") | last | split(".") | first) end' "$SCRIPT_DIR/apps.json" | xargs)

echo "Apps to install: $APP_LIST"

INSTALL_OK=()
INSTALL_FAIL=()

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
            echo "⚠️  $app failed to install. Continuing..."
            INSTALL_FAIL+=("$app")
        fi
    done

    echo ""
    echo "Running migrate..."
    "${COMPOSE_CMD[@]}" exec -T backend bench --site "$SITE_DOMAIN" migrate || echo "⚠️  Migration had warnings/errors."
else
    echo "Creating new site: $SITE_DOMAIN..."

    if ! "${COMPOSE_CMD[@]}" exec -T backend bench new-site "$SITE_DOMAIN" \
        --admin-password "$ADMIN_PASSWORD" \
        --db-root-username root \
        --db-root-password "$MYSQL_ROOT_PASSWORD" \
        --set-default; then

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
            echo "⚠️  $app failed to install. Continuing..."
            INSTALL_FAIL+=("$app")
        fi
    done
fi

# --- 8. Summary ---
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
        echo "    docker compose -f $COMPOSE_FILE -f $OVERRIDE_FILE exec backend bench --site $SITE_DOMAIN install-app $fail_app"
    done
fi

echo ""
echo "Currently installed apps:"
"${COMPOSE_CMD[@]}" exec -T backend bench --site "$SITE_DOMAIN" list-apps || true