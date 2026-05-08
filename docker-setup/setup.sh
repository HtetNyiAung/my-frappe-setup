#!/usr/bin/env bash

# Purpose: Fully automated stack build with selective custom app mounting.
# NOTE: We intentionally do NOT use 'set -e' so that individual app failures
# don't kill the entire setup. Critical steps check errors explicitly.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "$SCRIPT_DIR"

# Important runtime variables:
# - SCRIPT_DIR: absolute path to this docker-setup folder.
# - COMPOSE_CMD: Docker Compose command with base + generated override files.
# - APP_LIST: app names resolved from apps.json, for example "erpnext hrms".
# - IMAGE_BUILT: true only when this run builds a fresh custom image.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Fail early when a required CLI tool is missing.
require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: Required command '$1' is not installed or not in PATH."
        exit 1
    fi
}

# Load .env safely and export its variables for Docker Compose.
load_env() {
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    local status=$?
    set +a
    return "$status"
}

# Validate that required .env variables are present.
require_env() {
    local missing=()

    for var_name in "$@"; do
        if [ -z "${!var_name:-}" ]; then
            missing+=("$var_name")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required .env value(s): ${missing[*]}"
        exit 1
    fi
}

# Convert apps.json entries into installable app names.
# Uses .name when present, otherwise derives the name from the Git URL.
get_app_list() {
    jq -r '
        .[]
        | if .name then
            .name
          else
            (.url | split("/") | last | split(".") | first)
          end
    ' "$SCRIPT_DIR/apps.json" | xargs
}

# Confirm Docker is reachable before any build/start command runs.
ensure_docker_access() {
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker is not running or this user cannot access the Docker daemon."
        echo "Try one of these fixes:"
        echo "  - Start Docker Desktop / Docker Engine"
        echo "  - Run this script with a user that can access /var/run/docker.sock"
        echo "  - Add your user to the docker group, then log out and back in"
        exit 1
    fi
}

# Run a command inside the backend container.
compose_exec_backend() {
    "${COMPOSE_CMD[@]}" exec -T backend "$@"
}

# Run a bench command for the configured site inside the backend container.
bench_site() {
    compose_exec_backend bench --site "$SITE_DOMAIN" "$@"
}

# Clear Frappe's cached asset manifest after image/app changes.
# This prevents the browser from requesting old hashed CSS/JS bundle names.
refresh_asset_cache() {
    echo ""
    echo "Clearing stale Frappe asset cache..."

    bench_site clear-cache || true
    bench_site clear-website-cache || true

    bench_site console --autoreload <<-'PY' || true
	import frappe

	frappe.client_cache.delete_value("assets_json", shared=True)
	frappe.cache.delete_value("assets_json", shared=True)
	frappe.client_cache.clear_cache()
	frappe.clear_cache()
	print("assets_json cache cleared")
	PY

    "${COMPOSE_CMD[@]}" restart backend frontend websocket || true
}

# Repair a site database user when site_config.json and MariaDB passwords drift.
repair_site_db_credentials() {
    if [ ! -f "$SCRIPT_DIR/repair_db_credentials.py" ]; then
        echo "⚠️  repair_db_credentials.py not found. Cannot repair database credentials automatically."
        return 1
    fi

    echo "Repairing MariaDB credentials for site $SITE_DOMAIN..."

    # Keep the repair script on the host and copy it into the container only when needed.
    if ! "${COMPOSE_CMD[@]}" cp "$SCRIPT_DIR/repair_db_credentials.py" backend:/tmp/repair_db_credentials.py; then
        echo "⚠️  Could not copy repair_db_credentials.py into backend container."
        return 1
    fi

    compose_exec_backend /home/frappe/frappe-bench/env/bin/python \
        /tmp/repair_db_credentials.py "$SITE_DOMAIN"
}

# List installed apps, with one automatic retry after repairing DB credentials.
list_installed_apps() {
    local output
    local status

    output="$(bench_site list-apps 2>&1)"
    status=$?

    if [ $status -ne 0 ] && echo "$output" | grep -q "Access denied for user"; then
        echo "⚠️  Site database login failed. Trying automatic credential repair..."

        if repair_site_db_credentials; then
            output="$(bench_site list-apps 2>&1)"
            status=$?
        fi
    fi

    echo "$output"
    return $status
}

# Install apps one by one so a single app failure does not stop the whole setup.
install_apps_one_by_one() {
    local app
    local installed_apps

    installed_apps="$(list_installed_apps || true)"

    for app in $APP_LIST; do
        [ "$app" = "frappe" ] && continue

        if echo "$installed_apps" | awk '{print $1}' | grep -Fxq "$app"; then
            echo "✅ $app already installed. Skipping."
            INSTALL_SKIP+=("$app")
            continue
        fi

        echo ""
        echo "━━━ Installing: $app ━━━"

        # Some installs can partially succeed but return non-zero.
        # Run migrate and re-check before marking the app as failed.
        if bench_site install-app "$app" 2>&1; then
            echo "✅ $app installed successfully."
            INSTALL_OK+=("$app")
            installed_apps="$installed_apps
$app"
            continue
        fi

        echo "⚠️  $app install command returned an error. Running migrate and checking again..."
        bench_site migrate || true
        installed_apps="$(list_installed_apps || true)"

        if echo "$installed_apps" | awk '{print $1}' | grep -Fxq "$app"; then
            echo "✅ $app is installed after recovery migrate."
            INSTALL_OK+=("$app")
        else
            echo "⚠️  $app failed to install. Continuing..."
            INSTALL_FAIL+=("$app")
        fi
    done
}

check_requirements() {
    require_command git
    require_command jq
    require_command docker
}

load_configuration() {
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        if [ -f "$SCRIPT_DIR/.env.example" ]; then
            echo "No .env found. Copying from .env.example..."
            cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        else
            echo "Error: Neither .env nor .env.example found. Setup aborted."
            exit 1
        fi
    fi

    if ! load_env; then
        echo "Error: Failed to load $SCRIPT_DIR/.env. Check for invalid shell syntax."
        exit 1
    fi

    require_env \
        CUSTOM_IMAGE \
        FRAPPE_BRANCH \
        COMPOSE_FILE \
        SITE_DOMAIN \
        ADMIN_PASSWORD \
        MYSQL_ROOT_PASSWORD

    if [ ! -f "$SCRIPT_DIR/$COMPOSE_FILE" ]; then
        echo "Error: COMPOSE_FILE '$COMPOSE_FILE' was not found in $SCRIPT_DIR."
        exit 1
    fi

    if ! jq empty "$SCRIPT_DIR/apps.json" >/dev/null; then
        echo "Error: apps.json is not valid JSON."
        exit 1
    fi

    ensure_docker_access
    echo "Environment variables loaded from .env"
}

prepare_frappe_docker() {
    FRAPPE_PATH="$SCRIPT_DIR/frappe_docker"
    CUSTOM_APPS_DIR="$FRAPPE_PATH/apps"

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

    mkdir -p "$CUSTOM_APPS_DIR"
}

clone_custom_apps() {
    local branch
    local name
    local row
    local target_dir
    local url

    echo "Checking apps from apps.json for custom development apps..."

    VALID_CUSTOM_APPS=()
    CUSTOM_APPS=$(jq -c '.[] | select(.is_custom == true)' "$SCRIPT_DIR/apps.json")

    for row in $CUSTOM_APPS; do
        name=$(echo "$row" | jq -r '.name // (.url | split("/") | last | split(".") | first)')
        url=$(echo "$row" | jq -r '.url')
        branch=$(echo "$row" | jq -r '.branch // "main"')
        target_dir="$CUSTOM_APPS_DIR/$name"

        if [ ! -d "$target_dir" ]; then
            echo "Found new custom app: $name ($url). Cloning..."
            if ! git clone --branch "$branch" "$url" "$target_dir"; then
                echo "⚠️  Warning: Failed to clone $name. Skipping volume mount."
                continue
            fi
        else
            echo "Custom app $name exists on host."
        fi

        VALID_CUSTOM_APPS+=("$name")
    done
}

generate_compose_override() {
    local app_name
    local svc

    OVERRIDE_FILE="$SCRIPT_DIR/docker-compose.override.yml"
    SERVICES=("backend" "configurator" "create-site" "queue-long" "queue-short" "scheduler" "websocket")

    if [ ${#VALID_CUSTOM_APPS[@]} -eq 0 ]; then
        echo "services: {}" > "$OVERRIDE_FILE"
        echo "No valid custom apps found. Generated empty override file."
        return
    fi

    echo "services:" > "$OVERRIDE_FILE"

    for svc in "${SERVICES[@]}"; do
        echo "  $svc:" >> "$OVERRIDE_FILE"
        echo "    volumes:" >> "$OVERRIDE_FILE"

        for app_name in "${VALID_CUSTOM_APPS[@]}"; do
            echo "      - ./frappe_docker/apps/$app_name:/home/frappe/frappe-bench/apps/$app_name" >> "$OVERRIDE_FILE"
        done

        echo "✅ Configured $svc with ${#VALID_CUSTOM_APPS[@]} custom apps"
    done
}

validate_compose_config() {
    if ! docker compose -f "$COMPOSE_FILE" -f "$OVERRIDE_FILE" config >/dev/null; then
        echo "Error: Docker Compose configuration is invalid."
        exit 1
    fi
}

update_submodules() {
    echo "Updating git submodules (if any)..."
    git submodule update --init --recursive 2>/dev/null || true
}

parse_args() {
    FORCE_REBUILD=false

    if [[ "${1:-}" == "--rebuild" ]]; then
        FORCE_REBUILD=true
    fi
}

check_image_apps() {
    local app

    APP_LIST=$(get_app_list)
    IMAGE_HAS_APPS=false

    if ! docker image inspect "$CUSTOM_IMAGE" >/dev/null 2>&1; then
        return
    fi

    MISSING_IMAGE_APPS=()

    for app in $APP_LIST; do
        [ "$app" = "frappe" ] && continue

        if ! docker run --rm --entrypoint bash "$CUSTOM_IMAGE" \
            -lc "test -d /home/frappe/frappe-bench/apps/$app" >/dev/null 2>&1; then
            MISSING_IMAGE_APPS+=("$app")
        fi
    done

    if [ ${#MISSING_IMAGE_APPS[@]} -eq 0 ]; then
        IMAGE_HAS_APPS=true
    else
        echo "Image '$CUSTOM_IMAGE' is missing app(s): ${MISSING_IMAGE_APPS[*]}"
        echo "Rebuilding image so apps.json is included..."
    fi
}

build_custom_image() {
    IMAGE_BUILT=false
    check_image_apps

    if docker image inspect "$CUSTOM_IMAGE" >/dev/null 2>&1 &&
        [ "$FORCE_REBUILD" = false ] &&
        [ "$IMAGE_HAS_APPS" = true ]; then

        echo "Image '$CUSTOM_IMAGE' already contains apps from apps.json. Skipping build. (Use --rebuild to force)"
        return
    fi

    if [ "$FORCE_REBUILD" = true ] && [ -f "$SCRIPT_DIR/backup.sh" ]; then
        echo "Rebuilding image... Taking a safety backup first..."
        "$SCRIPT_DIR/backup.sh" || echo "Warning: Backup failed, but proceeding with rebuild..."
    fi

    cp "$SCRIPT_DIR/apps.json" "$FRAPPE_PATH/apps.json"
    cd "$FRAPPE_PATH" || exit 1

    echo "Building Image: $CUSTOM_IMAGE"

    if ! docker build \
        --build-arg FRAPPE_BRANCH="$FRAPPE_BRANCH" \
        --build-arg CACHE_BUST="$(date +%s)" \
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
    IMAGE_BUILT=true
}

start_containers() {
    local up_args

    cd "$SCRIPT_DIR" || exit 1
    COMPOSE_CMD=("docker" "compose" "-f" "$COMPOSE_FILE" "-f" "$OVERRIDE_FILE")

    echo "Starting containers..."

    up_args=("up" "-d")
    if [ "$IMAGE_BUILT" = true ]; then
        up_args+=("--force-recreate")
    fi

    if ! "${COMPOSE_CMD[@]}" "${up_args[@]}"; then
        echo ""
        echo "❌ CRITICAL ERROR: Docker failed to start containers."
        echo "Check internet access or Docker credential issues."
        echo "Common fix: mv ~/.docker/config.json ~/.docker/config.json.bak"
        exit 1
    fi

    echo "Waiting for stabilization (45s)..."
    sleep 45
}

wait_for_backend() {
    local i

    for i in {1..15}; do
        if compose_exec_backend bench list-sites >/dev/null 2>&1; then
            echo "✅ Backend is ready!"
            return 0
        fi

        echo "Waiting for backend... ($i/15)"
        sleep 10
    done

    echo "❌ Backend did not become ready in time. Aborting app installation."
    exit 1
}

refresh_sites_apps_txt() {
    echo "Refreshing sites/apps.txt from apps available in the image..."

    if ! compose_exec_backend bash -lc \
        "find apps -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort > sites/apps.txt && cat sites/apps.txt"; then
        echo "❌ Failed to refresh sites/apps.txt. Aborting app installation."
        exit 1
    fi
}

provision_site() {
    INSTALL_OK=()
    INSTALL_FAIL=()
    INSTALL_SKIP=()

    echo "Apps to install: $APP_LIST"
    wait_for_backend
    refresh_sites_apps_txt

    if compose_exec_backend bench list-sites | grep -q "$SITE_DOMAIN"; then
        echo "Site $SITE_DOMAIN exists. Installing/Updating apps one by one..."
        install_apps_one_by_one

        echo ""
        echo "Running migrate..."
        bench_site migrate || echo "⚠️  Migration had warnings/errors."
        return
    fi

    echo "Creating new site: $SITE_DOMAIN..."

    if ! compose_exec_backend bench new-site "$SITE_DOMAIN" \
        --admin-password "$ADMIN_PASSWORD" \
        --db-root-username root \
        --db-root-password "$MYSQL_ROOT_PASSWORD" \
        --set-default; then

        echo "❌ Failed to create site $SITE_DOMAIN. Aborting."
        exit 1
    fi

    echo "Installing apps to new site one by one..."
    install_apps_one_by_one
}

print_summary() {
    echo ""
    echo "══════════════════════════════════════════"
    echo "  Setup Complete! Site: $SITE_DOMAIN"
    echo "══════════════════════════════════════════"

    if [ ${#INSTALL_OK[@]} -gt 0 ]; then
        echo "  ✅ Installed: ${INSTALL_OK[*]}"
    fi

    if [ ${#INSTALL_SKIP[@]} -gt 0 ]; then
        echo "  ✅ Already installed: ${INSTALL_SKIP[*]}"
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
    list_installed_apps || true
}

main() {
    check_requirements
    load_configuration
    prepare_frappe_docker
    clone_custom_apps
    generate_compose_override
    validate_compose_config
    update_submodules
    parse_args "$@"
    build_custom_image
    start_containers
    provision_site
    refresh_asset_cache
    print_summary
}

main "$@"
