#!/usr/bin/env bash

# Purpose: Fully automated stack build with selective custom app mounting.
# NOTE: We intentionally do NOT use 'set -e' so that individual app failures
# don't kill the entire setup. Critical steps check errors explicitly.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
init_script_logging "$SCRIPT_DIR" "setup"

echo "$SCRIPT_DIR"

# Important runtime variables:
# - SCRIPT_DIR: absolute path to this docker-setup folder.
# - COMPOSE_CMD: Docker Compose command with base + generated override files.
# - APP_LIST: app names resolved from apps.json, for example "erpnext hrms".
# - IMAGE_BUILT: true only when this run builds a fresh custom image.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
    cat <<'EOF'
Usage: ./setup.sh [--rebuild] [--yes]

Options:
  --rebuild   Force a fresh custom image build.
  --yes, -y   Run without interactive confirmation (for trusted scripts).
  --help, -h  Show this help message.
EOF
}

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

is_truthy() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

confirm_setup() {
    if [ "$YES" -eq 1 ]; then
        return
    fi

    if [ ! -t 0 ]; then
        echo "Error: Interactive confirmation is unavailable. Use --yes for trusted automation."
        exit 1
    fi

    echo "=========================================="
    echo "Setup Target Site: $SITE_DOMAIN"
    echo "Custom Image:      $CUSTOM_IMAGE"
    echo "Force Rebuild:     $FORCE_REBUILD"
    echo "Database:          $DATABASE_MODE ($DB_HOST:$DB_PORT)"
    echo "S3 Storage:        $S3_STORAGE_ENABLED"
    echo "=========================================="

    local confirmation
    if ! read -r -p "Type SETUP to continue: " confirmation; then
        echo "Setup cancelled."
        exit 1
    fi
    if [ "$confirmation" != "SETUP" ]; then
        echo "Setup cancelled."
        exit 1
    fi
}

normalize_s3_storage_enabled() {
    case "${S3_STORAGE_ENABLED:-false}" in
        1|true|TRUE|yes|YES|on|ON)
            S3_STORAGE_ENABLED=true
            ;;
        0|false|FALSE|no|NO|off|OFF|"")
            S3_STORAGE_ENABLED=false
            ;;
        *)
            echo "Error: S3_STORAGE_ENABLED must be true or false."
            exit 1
            ;;
    esac

    export S3_STORAGE_ENABLED
}

normalize_database_configuration() {
    DATABASE_MODE="${DATABASE_MODE:-local}"
    DB_PORT="${DB_PORT:-3306}"

    case "$DATABASE_MODE" in
        local)
            DB_HOST="${DB_HOST:-db}"
            DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"
            ;;
        external)
            require_env DB_HOST
            if [ "$DB_HOST" = "db" ] || [ "$DB_HOST" = "localhost" ] || [ "$DB_HOST" = "127.0.0.1" ]; then
                echo "Error: External DB_HOST must be reachable from Docker containers, not '$DB_HOST'."
                exit 1
            fi
            ;;
        *)
            echo "Error: DATABASE_MODE must be local or external."
            exit 1
            ;;
    esac

    if ! [[ "$DB_PORT" =~ ^[1-9][0-9]{0,4}$ ]] || [ "$DB_PORT" -gt 65535 ]; then
        echo "Error: DB_PORT must be an integer between 1 and 65535."
        exit 1
    fi

    export DATABASE_MODE DB_HOST DB_PORT DB_ROOT_PASSWORD
}

preflight_external_database() {
    if [ "$DATABASE_MODE" != "external" ]; then
        return
    fi

    require_command python3
    echo "Checking external MariaDB network access at $DB_HOST:$DB_PORT..."
    if ! python3 - "$DB_HOST" "$DB_PORT" <<'PY'
import socket
import sys

host = sys.argv[1]
port = int(sys.argv[2])

try:
    with socket.create_connection((host, port), timeout=5):
        pass
except OSError as exc:
    raise SystemExit(f"External database is not reachable at {host}:{port}: {exc}") from exc

print(f"External database TCP connection is ready: {host}:{port}")
PY
    then
        echo "Error: External database preflight failed."
        echo "Check its private DNS/IP, firewall allowlist, MariaDB bind address, and port."
        exit 1
    fi
}

production_warning() {
    PRODUCTION_WARNING_COUNT=$((PRODUCTION_WARNING_COUNT + 1))
    echo "⚠️  Production warning: $1"
}

check_production_readiness() {
    PRODUCTION_WARNING_COUNT=0

    case "${SITE_DOMAIN:-}" in
        frontend|localhost|127.0.0.1|"")
            production_warning "SITE_DOMAIN is '$SITE_DOMAIN'. Use the real production domain before going live."
            ;;
    esac

    if [ "${BIND_ADDRESS:-0.0.0.0}" = "0.0.0.0" ]; then
        production_warning "BIND_ADDRESS is 0.0.0.0. For reverse-proxy production, prefer 127.0.0.1."
    fi

    for var_name in DB_PASSWORD ADMIN_PASSWORD KC_ADMIN_PASSWORD AUTHENTIK_BOOTSTRAP_PASSWORD; do
        case "${!var_name:-}" in
            ""|admin|password|changeme|keycloak_db_password|yoursecretkey_replacethis)
                production_warning "$var_name uses an empty/default value."
                ;;
        esac
    done

    if [ "$DATABASE_MODE" = "external" ] && [ -n "${DB_ROOT_PASSWORD:-}" ]; then
        case "$DB_ROOT_PASSWORD" in
            admin|password|changeme)
                production_warning "DB_ROOT_PASSWORD uses a default value."
                ;;
        esac
    fi

    if [ "$DATABASE_MODE" = "local" ]; then
        for var_name in MYSQL_ROOT_PASSWORD MARIADB_ROOT_PASSWORD; do
            case "${!var_name:-}" in
                ""|admin|password|changeme)
                    production_warning "$var_name uses an empty/default value."
                    ;;
            esac
        done
    fi

    if jq -e '.[] | select((.url | test("frappe/lms(.git)?$")) and (.branch == "develop"))' "$SCRIPT_DIR/apps.json" >/dev/null; then
        production_warning "LMS is pinned to the moving 'develop' branch. For production, prefer a release tag or commit SHA."
    fi

    if [ "$PRODUCTION_WARNING_COUNT" -gt 0 ] && is_truthy "${REQUIRE_PRODUCTION_READY:-0}"; then
        echo ""
        echo "REQUIRE_PRODUCTION_READY=1 is set, so setup is blocked until these warnings are fixed."
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
    ' "$SCRIPT_DIR/apps.json" |
        if is_truthy "$S3_STORAGE_ENABLED"; then
            xargs
        else
            awk '$0 != "frappe_s3_attachment"' | xargs
        fi
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

    {
        bench_site console --autoreload <<-'PY'
namespace = {}
exec("""
import frappe

frappe.client_cache.delete_value("assets_json", shared=True)
frappe.cache.delete_value("assets_json", shared=True)
frappe.client_cache.clear_cache()
frappe.clear_cache()
print("assets_json cache cleared")
""", namespace, namespace)
PY
    } || true

    "${COMPOSE_CMD[@]}" restart backend frontend websocket || true
}

apply_branding() {
    if [ -z "${PROJECT_NAME:-}" ] && [ -z "${PRIMARY_COLOR:-}" ]; then
        return
    fi

    echo ""
    echo "Applying branding from .env..."

    {
        compose_exec_backend env \
            PROJECT_NAME="${PROJECT_NAME:-}" \
            PRIMARY_COLOR="${PRIMARY_COLOR:-}" \
            SYSTEM_LANGUAGE="${SYSTEM_LANGUAGE:-en}" \
            SYSTEM_TIME_ZONE="${SYSTEM_TIME_ZONE:-Asia/Yangon}" \
            bench --site "$SITE_DOMAIN" console --autoreload <<-'PY'
namespace = {}
exec("""
import os
import frappe

project_name = os.environ.get("PROJECT_NAME", "").strip()
primary_color = os.environ.get("PRIMARY_COLOR", "").strip()
system_language = os.environ.get("SYSTEM_LANGUAGE", "en").strip() or "en"
system_time_zone = os.environ.get("SYSTEM_TIME_ZONE", "Asia/Yangon").strip() or "Asia/Yangon"

TEXT_FIELD_TYPES = {"Data", "Text", "Small Text", "Long Text", "Text Editor", "Code", "HTML", "Color"}
SAFE_VALUE_FIELD_TYPES = TEXT_FIELD_TYPES | {"Check", "Int", "Float"}

def get_field(meta, fieldname):
    return next((field for field in meta.fields if field.fieldname == fieldname), None)

def ensure_system_settings_defaults(doc, meta):
    changed = False

    if get_field(meta, "language") and not doc.get("language"):
        language = system_language
        if not frappe.db.exists("Language", language):
            language = "en"
        doc.set("language", language)
        changed = True

    if get_field(meta, "time_zone") and not doc.get("time_zone"):
        doc.set("time_zone", system_time_zone)
        changed = True

    return changed

def set_existing_fields(doctype, values):
    if not frappe.db.exists("DocType", doctype):
        return

    meta = frappe.get_meta(doctype)
    doc = frappe.get_single(doctype)
    changed = ensure_system_settings_defaults(doc, meta) if doctype == "System Settings" else False

    for fieldname, value in values.items():
        field = get_field(meta, fieldname)
        if value not in (None, "") and field and field.fieldtype in SAFE_VALUE_FIELD_TYPES:
            doc.set(fieldname, value)
            changed = True

    if changed:
        doc.save(ignore_permissions=True)
        print(f"Updated {doctype}")

def set_doc_fields(doctype, name, values):
    if not frappe.db.exists(doctype, name):
        return

    meta = frappe.get_meta(doctype)
    doc = frappe.get_doc(doctype, name)
    changed = False

    for fieldname, value in values.items():
        field = get_field(meta, fieldname)
        if value not in (None, "") and field and field.fieldtype in SAFE_VALUE_FIELD_TYPES:
            doc.set(fieldname, value)
            changed = True

    if changed:
        doc.save(ignore_permissions=True)
        print(f"Updated {doctype}: {name}")

def set_website_theme(theme_name, primary_color):
    if not primary_color or not frappe.db.exists("DocType", "Website Theme"):
        return None

    existing_theme = frappe.db.exists("Website Theme", theme_name)
    doc = frappe.get_doc("Website Theme", existing_theme) if existing_theme else frappe.new_doc("Website Theme")
    meta = frappe.get_meta("Website Theme")

    if get_field(meta, "theme"):
        doc.set("theme", theme_name)

    values = {
        "custom": 1,
        "button_color": primary_color,
        "button_text_color": "#ffffff",
        "primary_color": primary_color,
        "link_color": primary_color,
        "custom_scss": (
            f":root {{ --primary: {primary_color}; --primary-color: {primary_color}; }}\\n"
            f".btn-primary {{ background-color: {primary_color}; border-color: {primary_color}; }}\\n"
            f"a {{ color: {primary_color}; }}"
        ),
    }

    for fieldname, value in values.items():
        field = get_field(meta, fieldname)
        if not field:
            continue
        if field.fieldtype == "Check" or field.fieldtype in TEXT_FIELD_TYPES:
            doc.set(fieldname, value)

    if doc.is_new():
        doc.insert(ignore_permissions=True, ignore_links=True)
    else:
        doc.save(ignore_permissions=True)

    print(f"Updated Website Theme: {doc.name}")
    return doc.name

learning_icon = (
    frappe.db.exists("Desktop Icon", "Frappe Learning")
    or frappe.db.exists("Desktop Icon", {"app": "lms", "icon_type": "App"})
)
if learning_icon:
    current_label = frappe.db.get_value("Desktop Icon", learning_icon, "label")
    if current_label != "Digital Learning":
        existing_with_target_label = frappe.db.exists("Desktop Icon", {"label": "Digital Learning"})
        if not existing_with_target_label:
            frappe.db.set_value(
                "Desktop Icon",
                learning_icon,
                "label",
                "Digital Learning",
                update_modified=False,
            )
            print(f"Updated Desktop Icon: {learning_icon} -> Digital Learning")
        else:
            print(f"Desktop Icon with label 'Digital Learning' already exists ({existing_with_target_label}). Skipping update.")
    else:
        print(f"Desktop Icon {learning_icon} is already named 'Digital Learning'.")

if project_name:
    set_existing_fields("System Settings", {
        "app_name": project_name,
    })
    set_existing_fields("Website Settings", {
        "app_name": project_name,
        "brand_html": project_name,
        "title_prefix": project_name,
    })
    set_doc_fields("LMS Course", "a-guide-to-frappe-learning", {
        "title": f"A guide to {project_name}",
        "short_introduction": f"Learn the basics of {project_name} and how to get started with your very first course.",
    })

    if frappe.db.exists("LMS Course", "a-guide-to-frappe-learning"):
        course = frappe.get_doc("LMS Course", "a-guide-to-frappe-learning")
        if course.get("description"):
            course.description = course.description.replace("Frappe Learning", project_name)
            course.save(ignore_permissions=True)
            print("Updated LMS Course description: a-guide-to-frappe-learning")

theme_name = set_website_theme(project_name or "Custom LMS Theme", primary_color)
if theme_name:
    set_existing_fields("Website Settings", {
        "website_theme": theme_name,
    })

frappe.db.commit()
print("Branding applied")
""", namespace, namespace)
PY
    } || true
}

apply_public_url() {
    if [ -z "${PUBLIC_URL:-}" ]; then
        return
    fi

    echo ""
    echo "Applying public URL from .env..."
    bench_site set-config host_name "$PUBLIC_URL"
    echo "Public URL set to: $PUBLIC_URL"
}

apply_s3_storage_config() {
    if ! is_truthy "$S3_STORAGE_ENABLED"; then
        return
    fi

    echo ""
    echo "Applying MinIO S3 storage configuration..."

    # Keep endpoint in site_config for future reference / custom code.
    bench_site set-config s3_endpoint_url "$S3_ENDPOINT_URL"

    # Write credentials directly to the S3 File Attachment DocType.
    # The frappe_s3_attachment app reads from this DocType, not site_config.
    {
        compose_exec_backend env \
            S3_ACCESS_KEY="${S3_ACCESS_KEY:-admin}" \
            S3_SECRET_KEY="${S3_SECRET_KEY:-ChangeThisStrongPassword123!}" \
            S3_BUCKET_NAME="${S3_BUCKET_NAME:-app-public}" \
            S3_REGION="${S3_REGION:-us-east-1}" \
            bench --site "$SITE_DOMAIN" console --autoreload <<-'PY'
namespace = {}
exec("""
import os
import frappe

if not frappe.db.exists("DocType", "S3 File Attachment"):
    print("S3 File Attachment DocType not found. Skipping S3 config.")
else:
    doc = frappe.get_single("S3 File Attachment")
    doc.aws_key = os.environ.get("S3_ACCESS_KEY", "")
    doc.aws_secret = os.environ.get("S3_SECRET_KEY", "")
    doc.bucket_name = os.environ.get("S3_BUCKET_NAME", "")
    doc.region_name = os.environ.get("S3_REGION", "us-east-1")
    doc.save(ignore_permissions=True)
    frappe.db.commit()
    print("S3 File Attachment settings applied")
""", namespace, namespace)
PY
    } || echo "⚠️  Failed to apply S3 File Attachment settings. Configure manually in Desk UI."
}

preflight_s3_storage() {
    if ! is_truthy "$S3_STORAGE_ENABLED"; then
        return
    fi

    echo ""
    echo "Checking MinIO S3 endpoint and bucket..."

    if ! compose_exec_backend env \
        S3_ENDPOINT_URL="$S3_ENDPOINT_URL" \
        S3_ACCESS_KEY="$S3_ACCESS_KEY" \
        S3_SECRET_KEY="$S3_SECRET_KEY" \
        S3_BUCKET_NAME="$S3_BUCKET_NAME" \
        S3_REGION="${S3_REGION:-us-east-1}" \
        /home/frappe/frappe-bench/env/bin/python -c '
import os
import boto3

client = boto3.client(
    "s3",
    endpoint_url=os.environ["S3_ENDPOINT_URL"],
    aws_access_key_id=os.environ["S3_ACCESS_KEY"],
    aws_secret_access_key=os.environ["S3_SECRET_KEY"],
    region_name=os.environ["S3_REGION"],
)
client.head_bucket(Bucket=os.environ["S3_BUCKET_NAME"])
print("S3 endpoint and bucket are ready")
'; then
        echo "Error: S3 storage preflight failed."
        echo "Verify MinIO is reachable and bucket '$S3_BUCKET_NAME' exists, then rerun setup.sh."
        exit 1
    fi
}

count_s3_backed_files() {
    local output

    output="$({
        compose_exec_backend env \
            S3_BUCKET_NAME="${S3_BUCKET_NAME:-}" \
            bench --site "$SITE_DOMAIN" console --autoreload <<-'PY'
namespace = {}
exec("""
import os
import frappe

bucket = os.environ.get("S3_BUCKET_NAME", "").strip()
private_pattern = "/api/method/frappe_s3_attachment.controller.generate_file%"
public_pattern = f"%/{bucket}/%" if bucket else ""

if public_pattern:
    count = frappe.db.sql(
        '''SELECT COUNT(*) FROM `tabFile`
        WHERE file_url LIKE %s OR file_url LIKE %s''',
        (private_pattern, public_pattern),
    )[0][0]
else:
    count = frappe.db.count("File", {"file_url": ["like", private_pattern]})

print(f"S3_BACKED_FILE_COUNT={count}")
""", namespace, namespace)
PY
    } 2>&1)" || return 1

    echo "$output" |
        sed -n 's/.*S3_BACKED_FILE_COUNT=\([0-9][0-9]*\).*/\1/p' |
        tail -n 1
}

reconcile_s3_storage_mode() {
    local installed_apps
    local s3_file_count

    installed_apps="$(list_installed_apps || true)"

    if is_truthy "$S3_STORAGE_ENABLED"; then
        return
    fi

    if ! echo "$installed_apps" | awk '{print $1}' | grep -Fxq "frappe_s3_attachment"; then
        echo "Local file storage enabled. S3 attachment hooks are not installed on this site."
        return
    fi

    s3_file_count="$(count_s3_backed_files)" || {
        echo "Error: Could not check for existing S3-backed File records."
        echo "Refusing to disable frappe_s3_attachment without a successful safety check."
        exit 1
    }

    if ! [[ "$s3_file_count" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid S3-backed file count: '$s3_file_count'."
        exit 1
    fi

    if [ "$s3_file_count" -gt 0 ]; then
        echo "Error: Cannot switch to local storage while $s3_file_count S3-backed File record(s) remain."
        echo "Migrate those objects and File URLs to local storage before setting S3_STORAGE_ENABLED=false."
        exit 1
    fi

    echo "No S3-backed files found. Removing S3 attachment hooks from site $SITE_DOMAIN..."
    bench_site uninstall-app --yes frappe_s3_attachment
}


# Repair a site database user when site_config.json and MariaDB passwords drift.
repair_site_db_credentials() {
    if [ ! -f "$SCRIPT_DIR/repair_db_credentials.py" ]; then
        echo "⚠️  repair_db_credentials.py not found. Cannot repair database credentials automatically."
        return 1
    fi

    if [ "$DATABASE_MODE" = "external" ] && ! is_truthy "${ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR:-false}"; then
        echo "External database credential repair is disabled."
        echo "Set ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=true only for a controlled repair."
        return 1
    fi
    if [ "$DATABASE_MODE" = "external" ] &&
        { [ -z "${DB_ROOT_USERNAME:-}" ] || [ -z "${DB_ROOT_PASSWORD:-}" ]; }; then
        echo "External database repair requires DB_ROOT_USERNAME and DB_ROOT_PASSWORD."
        return 1
    fi

    echo "Repairing MariaDB credentials for site $SITE_DOMAIN on $DB_HOST:$DB_PORT..."

    # Keep the repair script on the host and copy it into the container only when needed.
    if ! "${COMPOSE_CMD[@]}" cp "$SCRIPT_DIR/repair_db_credentials.py" backend:/tmp/repair_db_credentials.py; then
        echo "⚠️  Could not copy repair_db_credentials.py into backend container."
        return 1
    fi

    compose_exec_backend env \
        DATABASE_MODE="$DATABASE_MODE" \
        DB_HOST="$DB_HOST" \
        DB_PORT="$DB_PORT" \
        DB_ROOT_USERNAME="${DB_ROOT_USERNAME:-root}" \
        DB_ROOT_PASSWORD="$DB_ROOT_PASSWORD" \
        /home/frappe/frappe-bench/env/bin/python \
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

    normalize_s3_storage_enabled
    normalize_database_configuration

    require_env \
        CUSTOM_IMAGE \
        FRAPPE_BRANCH \
        COMPOSE_FILE \
        SITE_DOMAIN \
        ADMIN_PASSWORD

    if [ "$DATABASE_MODE" = "local" ]; then
        require_env MYSQL_ROOT_PASSWORD MARIADB_ROOT_PASSWORD
    fi

    if is_truthy "$S3_STORAGE_ENABLED"; then
        require_env \
            S3_ENDPOINT_URL \
            S3_ACCESS_KEY \
            S3_SECRET_KEY \
            S3_BUCKET_NAME
    fi

    if [ ! -f "$SCRIPT_DIR/$COMPOSE_FILE" ]; then
        echo "Error: COMPOSE_FILE '$COMPOSE_FILE' was not found in $SCRIPT_DIR."
        exit 1
    fi

    if ! jq empty "$SCRIPT_DIR/apps.json" >/dev/null; then
        echo "Error: apps.json is not valid JSON."
        exit 1
    fi

    check_production_readiness
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
            if [ -d "$target_dir/.git" ]; then
                echo "Syncing $name from origin/$branch..."
                if ! git -C "$target_dir" fetch origin "$branch"; then
                    echo "⚠️  Warning: Failed to fetch $name. Using existing files."
                elif ! git -C "$target_dir" reset --hard "origin/$branch"; then
                    echo "⚠️  Warning: Failed to reset $name to origin/$branch."
                else
                    echo "✅ $name synced to origin/$branch"
                fi
            fi
        fi

        if [ -x "$target_dir/scripts/verify_package_layout.sh" ]; then
            "$target_dir/scripts/verify_package_layout.sh" "$target_dir" || {
                echo "⚠️  Warning: $name failed package layout verification."
            }
        elif [ ! -f "$target_dir/$name/__init__.py" ] && [ ! -f "$target_dir/__init__.py" ]; then
            echo "⚠️  Warning: $name is missing a Python package (__init__.py)."
            echo "    Run: git -C \"$target_dir\" fetch origin && git -C \"$target_dir\" reset --hard origin/$branch"
        fi

        VALID_CUSTOM_APPS+=("$name")
    done
}

generate_compose_override() {
    local app_name
    local db_dependent
    local svc

    OVERRIDE_FILE="$SCRIPT_DIR/docker-compose.override.yml"
    SERVICES=("backend" "frontend" "configurator" "create-site" "queue-long" "queue-short" "scheduler" "websocket")
    DB_DEPENDENT_SERVICES=("backend" "create-site" "queue-long" "queue-short" "scheduler")

    if [ "$DATABASE_MODE" = "external" ] &&
        [ ${#VALID_CUSTOM_APPS[@]} -eq 0 ] &&
        ! is_truthy "$S3_STORAGE_ENABLED"; then
        echo "services: {}" > "$OVERRIDE_FILE"
        echo "No custom app mounts, S3 settings, or local DB dependencies are needed. Generated empty override file."
        return
    fi

    echo "services:" > "$OVERRIDE_FILE"

    for svc in "${SERVICES[@]}"; do
        db_dependent=false
        if [ "$DATABASE_MODE" = "local" ] &&
            [[ " ${DB_DEPENDENT_SERVICES[*]} " == *" $svc "* ]]; then
            db_dependent=true
        fi

        if [ "$db_dependent" = false ] &&
            [ ${#VALID_CUSTOM_APPS[@]} -eq 0 ] &&
            ! is_truthy "$S3_STORAGE_ENABLED"; then
            continue
        fi

        echo "  $svc:" >> "$OVERRIDE_FILE"

        if [ "$db_dependent" = true ]; then
            echo "    depends_on:" >> "$OVERRIDE_FILE"
            echo "      db:" >> "$OVERRIDE_FILE"
            echo "        condition: service_healthy" >> "$OVERRIDE_FILE"
        fi

        # Inject AWS_ENDPOINT_URL for MinIO S3 compatibility.
        # boto3 SDK (v1.31.0+) reads this env var automatically,
        # so frappe_s3_attachment connects to MinIO instead of AWS.
        if is_truthy "$S3_STORAGE_ENABLED"; then
            echo "    environment:" >> "$OVERRIDE_FILE"
            echo "      AWS_ENDPOINT_URL: ${S3_ENDPOINT_URL}" >> "$OVERRIDE_FILE"
        fi

        if [ ${#VALID_CUSTOM_APPS[@]} -gt 0 ]; then
            echo "    volumes:" >> "$OVERRIDE_FILE"

            for app_name in "${VALID_CUSTOM_APPS[@]}"; do
                echo "      - ./frappe_docker/apps/$app_name:/home/frappe/frappe-bench/apps/$app_name" >> "$OVERRIDE_FILE"
            done
        fi

        echo "✅ Configured $svc with ${#VALID_CUSTOM_APPS[@]} custom apps (DB: $DATABASE_MODE, S3: $S3_STORAGE_ENABLED)"
    done
}

configure_compose_command() {
    COMPOSE_CMD=("docker" "compose" "-f" "$COMPOSE_FILE" "-f" "$OVERRIDE_FILE")
}

validate_compose_config() {
    if ! "${COMPOSE_CMD[@]}" config >/dev/null; then
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
    YES=0

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --rebuild)
                FORCE_REBUILD=true
                ;;
            --yes|-y)
                YES=1
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Error: Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
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

    if [ "$FORCE_REBUILD" = true ] && is_truthy "${AUTO_BACKUP_BEFORE_SETUP:-1}" && [ -f "$SCRIPT_DIR/backup.sh" ]; then
        if docker ps -q -f "name=^/${BACKEND_CONTAINER}$" | grep -q .; then
            if docker exec "$BACKEND_CONTAINER" bench list-sites 2>/dev/null | grep -Fxq "$SITE_DOMAIN"; then
                echo "Rebuilding image... Taking a safety backup first..."

                if ! "$SCRIPT_DIR/backup.sh" --yes; then
                    if is_truthy "${REQUIRE_BACKUP_BEFORE_SETUP:-0}"; then
                        echo "Backup failed and REQUIRE_BACKUP_BEFORE_SETUP=1 is set. Aborting."
                        exit 1
                    fi

                    echo "Warning: Backup failed, but proceeding because REQUIRE_BACKUP_BEFORE_SETUP is not enabled."
                fi
            else
                echo "No existing site '$SITE_DOMAIN' found in backend container. Skipping pre-rebuild backup."
            fi
        else
            echo "Backend container '$BACKEND_CONTAINER' is not running. Skipping pre-rebuild backup."
        fi
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
    echo "Starting containers with $DATABASE_MODE database mode..."

    up_args=("up" "-d")
    # Recreate when the image changed or custom app volume mounts must be applied.
    if [ "$IMAGE_BUILT" = true ] || [ ${#VALID_CUSTOM_APPS[@]} -gt 0 ]; then
        up_args+=("--force-recreate")
    fi

    if [ "$DATABASE_MODE" = "external" ]; then
        up_args+=(
            backend
            configurator
            create-site
            frontend
            queue-long
            queue-short
            redis-cache
            redis-queue
            scheduler
            websocket
        )
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

install_custom_apps_editable() {
    local app_name
    local app_dir
    local bench_root="/home/frappe/frappe-bench"

    if [ ${#VALID_CUSTOM_APPS[@]} -eq 0 ]; then
        return
    fi

    echo "Installing volume-mounted custom apps in editable mode..."

    for app_name in "${VALID_CUSTOM_APPS[@]}"; do
        app_dir="$bench_root/apps/$app_name"

        if ! compose_exec_backend bash -lc \
            "test -f \"$app_dir/$app_name/__init__.py\" || test -f \"$app_dir/__init__.py\""; then
            echo "❌ $app_name Python package is missing in the container mount."
            echo "   Expected: $app_dir/$app_name/__init__.py"
            echo "   Restore the git clone on the host, then rerun setup.sh."
            continue
        fi

        if ! compose_exec_backend bash -lc \
            "test -f \"$app_dir/pyproject.toml\" || test -f \"$app_dir/setup.py\""; then
            echo "⚠️  $app_name has no pyproject.toml/setup.py in the container mount."
            echo "   Expected: $app_dir/pyproject.toml"
            echo "   Skipping pip install."
            continue
        fi

        if compose_exec_backend bash -lc \
            "cd \"$bench_root\" && ./env/bin/pip install --quiet -e \"apps/$app_name\""; then
            echo "✅ pip install -e apps/$app_name"
        else
            echo "⚠️  pip install failed for $app_name. Continuing..."
        fi
    done
}

# Custom apps (apps.json is_custom: true) may define {app}.install.ensure_app_schema
# for app-specific schema repair. Otherwise sync_for(app, force=True) is used.
repair_custom_app_schema() {
    local app_name=$1
    local repaired=0

    # bench execute only accepts a dotted callable path (eval mode), not inline Python.
    if bench_site execute "${app_name}.install.ensure_app_schema" 2>/dev/null; then
        repaired=1
    elif bench_site execute frappe.model.sync.sync_for \
        --args "[\"${app_name}\"]" --kwargs '{"force": 1}' 2>/dev/null; then
        repaired=1
    fi

    if [ "$repaired" -eq 1 ]; then
        bench_site execute frappe.db.commit 2>/dev/null || true
        echo "✅ Schema repair completed for $app_name"
        return 0
    fi

    echo "⚠️  Schema repair failed for $app_name."
    return 1
}

repair_custom_apps_if_needed() {
    local app_name

    if [ ${#VALID_CUSTOM_APPS[@]} -eq 0 ]; then
        return
    fi

    for app_name in "${VALID_CUSTOM_APPS[@]}"; do
        if ! bench_site list-apps 2>/dev/null | awk '{print $1}' | grep -Fxq "$app_name"; then
            continue
        fi

        echo "Repairing $app_name schema (if needed)..."
        repair_custom_app_schema "$app_name"
    done
}

create_new_site() {
    require_env DB_ROOT_USERNAME DB_ROOT_PASSWORD

    local db_root_username="${DB_ROOT_USERNAME:-root}"
    local -a new_site_args=(
        bench new-site "$SITE_DOMAIN"
        --admin-password "$ADMIN_PASSWORD"
        --db-root-username "$db_root_username"
        --db-root-password "$DB_ROOT_PASSWORD"
        --set-default
    )

    if [ -n "${DB_NAME:-}" ]; then
        new_site_args+=(--db-name "$DB_NAME")
    fi

    if [ -n "${DB_PASSWORD:-}" ]; then
        new_site_args+=(--db-password "$DB_PASSWORD")
    fi

    echo "Using database server: $DB_HOST:$DB_PORT ($DATABASE_MODE)"
    echo "Using db-root-username: $db_root_username"
    if [ -n "${DB_NAME:-}" ]; then
        echo "Using db-name: $DB_NAME"
    else
        echo "Using Frappe default db-name (derived from SITE_DOMAIN)"
    fi

    compose_exec_backend "${new_site_args[@]}"
}

provision_site() {
    INSTALL_OK=()
    INSTALL_FAIL=()
    INSTALL_SKIP=()

    echo "Apps to install: $APP_LIST"
    wait_for_backend
    install_custom_apps_editable
    refresh_sites_apps_txt

    preflight_s3_storage

    if compose_exec_backend bench list-sites | grep -q "$SITE_DOMAIN"; then
        if ! list_installed_apps >/dev/null; then
            echo "Error: Existing site '$SITE_DOMAIN' cannot connect to $DB_HOST:$DB_PORT."
            echo "Verify that its database and site user were migrated before switching DATABASE_MODE."
            exit 1
        fi

        reconcile_s3_storage_mode
        echo "Site $SITE_DOMAIN exists. Installing/Updating apps one by one..."
        install_apps_one_by_one

        echo ""
        repair_custom_apps_if_needed
        echo "Running migrate..."
        bench_site migrate || echo "⚠️  Migration had warnings/errors."
        return
    fi

    echo "Creating new site: $SITE_DOMAIN..."

    if ! create_new_site; then
        echo "❌ Failed to create site $SITE_DOMAIN. Aborting."
        exit 1
    fi

    echo "Installing apps to new site one by one..."
    install_apps_one_by_one

    echo ""
    repair_custom_apps_if_needed
    echo "Running migrate..."
    bench_site migrate || echo "⚠️  Migration had warnings/errors."
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
    parse_args "$@"
    check_requirements
    load_configuration
    apply_script_log_retention "${SCRIPT_LOG_RETENTION_DAYS:-30}"
    confirm_setup
    preflight_external_database
    ensure_docker_access
    prepare_frappe_docker
    clone_custom_apps
    generate_compose_override
    configure_compose_command
    validate_compose_config
    update_submodules
    build_custom_image
    start_containers
    provision_site
    apply_public_url
    apply_s3_storage_config
    apply_branding
    refresh_asset_cache
    print_summary
}

main "$@"
