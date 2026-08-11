#!/usr/bin/env bash
# Purpose: Check and apply production-safe Frappe runtime settings.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
init_script_logging "$SCRIPT_DIR" "production"

YES=0
COMMAND=""
CHECK_FAILURES=0
APPLY_ACTIVE=0

usage() {
    cat <<'EOF'
Usage: ./production.sh <check|apply|verify> [--yes]

Commands:
  check    Read-only environment, container, and Frappe production checks.
  apply    Back up the site, apply production settings, migrate, and restart.
  verify   Read-only verification of settings applied by this script.

Options:
  --yes, -y  Skip the typed PRODUCTION confirmation for trusted automation.
  --help, -h Show this help message.
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            check|apply|verify)
                if [ -n "$COMMAND" ]; then
                    echo "Error: Specify only one command."
                    exit 1
                fi
                COMMAND="$1"
                ;;
            --yes|-y)
                YES=1
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Error: Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done

    if [ -z "$COMMAND" ]; then
        usage
        exit 1
    fi
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: Required command '$1' is not installed or not in PATH."
        exit 1
    fi
}

load_configuration() {
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        echo "Error: $SCRIPT_DIR/.env does not exist."
        exit 1
    fi

    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    set +a

    : "${COMPOSE_FILE:?COMPOSE_FILE is required in .env}"
    : "${BACKEND_CONTAINER:?BACKEND_CONTAINER is required in .env}"
    : "${SITE_DOMAIN:?SITE_DOMAIN is required in .env}"

    if [ ! -f "$SCRIPT_DIR/$COMPOSE_FILE" ]; then
        echo "Error: Compose file '$COMPOSE_FILE' was not found."
        exit 1
    fi

    COMPOSE_CMD=(docker compose -f "$COMPOSE_FILE")
    if [ -f "$SCRIPT_DIR/docker-compose.override.yml" ]; then
        COMPOSE_CMD+=(-f docker-compose.override.yml)
    fi
}

is_truthy() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

check_pass() {
    echo "[PASS] $1"
}

check_warn() {
    echo "[WARN] $1"
}

check_fail() {
    CHECK_FAILURES=$((CHECK_FAILURES + 1))
    echo "[FAIL] $1"
}

is_default_secret() {
    case "${1:-}" in
        ""|admin|password|changeme|keycloak_db_password|authentik_db_password|yoursecretkey_replacethis)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

check_environment() {
    local value
    local var_name

    echo "Checking production environment..."

    if [ "${DEPLOYMENT_MODE:-development}" = "production" ]; then
        check_pass "DEPLOYMENT_MODE is production."
    else
        check_fail "Set DEPLOYMENT_MODE=production in .env."
    fi

    case "${PUBLIC_URL:-}" in
        https://localhost*|https://127.0.0.1*|https://frontend*|"")
            check_fail "PUBLIC_URL must be the real public HTTPS URL."
            ;;
        https://*)
            check_pass "PUBLIC_URL uses HTTPS."
            ;;
        *)
            check_fail "PUBLIC_URL must start with https://."
            ;;
    esac

    case "${BIND_ADDRESS:-0.0.0.0}" in
        127.0.0.1|::1)
            check_pass "Frappe is bound to a loopback address for reverse proxy use."
            ;;
        *)
            check_fail "Set BIND_ADDRESS=127.0.0.1 before production launch."
            ;;
    esac

    if is_truthy "${REQUIRE_PRODUCTION_READY:-0}"; then
        check_pass "REQUIRE_PRODUCTION_READY is enabled."
    else
        check_fail "Set REQUIRE_PRODUCTION_READY=1 so setup blocks unsafe defaults."
    fi

    for var_name in DB_PASSWORD ADMIN_PASSWORD KC_ADMIN_PASSWORD AUTHENTIK_BOOTSTRAP_PASSWORD AUTHENTIK_SECRET_KEY; do
        value="${!var_name:-}"
        if is_default_secret "$value"; then
            check_fail "$var_name is empty or uses a known default value."
        else
            check_pass "$var_name is not a known default value."
        fi
    done

    if [ "${DATABASE_MODE:-local}" = "local" ]; then
        for var_name in MYSQL_ROOT_PASSWORD MARIADB_ROOT_PASSWORD; do
            value="${!var_name:-}"
            if is_default_secret "$value"; then
                check_fail "$var_name is empty or uses a known default value."
            else
                check_pass "$var_name is not a known default value."
            fi
        done
    fi

    if jq -e '.[] | select(.url | test("://[^/@]+@"))' "$SCRIPT_DIR/apps.json" >/dev/null; then
        check_fail "apps.json contains credentials in a Git URL; use a deploy key or credential helper."
    else
        check_pass "apps.json Git URLs do not contain embedded credentials."
    fi

    if jq -e '.[] | select((.branch // "") | test("^(develop|main|master)$"))' \
        "$SCRIPT_DIR/apps.json" >/dev/null; then
        check_warn "One or more apps use a moving branch; deploy a tested tag or commit when possible."
    else
        check_pass "App sources do not use common moving branch names."
    fi

    if [[ "${BACKUP_RETENTION_DAYS:-}" =~ ^[1-9][0-9]*$ ]]; then
        check_pass "Host backup retention is configured."
    else
        check_fail "BACKUP_RETENTION_DAYS must be a positive integer."
    fi

    if [ -x "$SCRIPT_DIR/backup.sh" ]; then
        check_pass "backup.sh is executable."
    else
        check_fail "backup.sh is missing or is not executable."
    fi

    if [ -n "${FRAPPE_RATE_LIMIT:-}" ] || [ -n "${FRAPPE_RATE_LIMIT_WINDOW:-}" ]; then
        if [[ "${FRAPPE_RATE_LIMIT:-}" =~ ^[1-9][0-9]*$ ]] &&
            [[ "${FRAPPE_RATE_LIMIT_WINDOW:-}" =~ ^[1-9][0-9]*$ ]]; then
            check_pass "Frappe rate limiting values are valid."
        else
            check_fail "FRAPPE_RATE_LIMIT and FRAPPE_RATE_LIMIT_WINDOW must both be positive integers."
        fi
    fi
}

check_runtime() {
    local service

    echo "Checking Docker and Frappe runtime..."
    if ! docker info >/dev/null 2>&1; then
        check_fail "Docker daemon is unavailable to the current user."
        return
    fi
    check_pass "Docker daemon is available."

    if ! "${COMPOSE_CMD[@]}" config >/dev/null 2>&1; then
        check_fail "Docker Compose configuration is invalid."
        return
    fi
    check_pass "Docker Compose configuration is valid."

    for service in backend frontend queue-long queue-short scheduler websocket; do
        if [ -n "$("${COMPOSE_CMD[@]}" ps -q --status running "$service" 2>/dev/null)" ]; then
            check_pass "Service '$service' is running."
        else
            check_fail "Service '$service' is not running."
        fi
    done

    if docker exec "$BACKEND_CONTAINER" test -d \
        "/home/frappe/frappe-bench/sites/$SITE_DOMAIN"; then
        check_pass "Site '$SITE_DOMAIN' exists."
    else
        check_fail "Site '$SITE_DOMAIN' is not available in the backend container."
        return
    fi

    if docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" list-apps >/dev/null 2>&1; then
        check_pass "Site database connection is working."
    else
        check_fail "Site database connection failed."
    fi
}

check_s3() {
    if ! is_truthy "${S3_STORAGE_ENABLED:-false}"; then
        check_pass "S3 storage is disabled; local file storage will be used."
        return
    fi

    echo "Checking S3 storage..."
    if [ -z "${S3_ENDPOINT_URL:-}" ] || [ -z "${S3_ACCESS_KEY:-}" ] ||
        [ -z "${S3_SECRET_KEY:-}" ] || [ -z "${S3_BUCKET_NAME:-}" ]; then
        check_fail "S3 is enabled but its endpoint, credentials, or bucket is missing."
        return
    fi

    if docker exec \
        -e CHECK_S3_ENDPOINT="$S3_ENDPOINT_URL" \
        -e CHECK_S3_ACCESS_KEY="$S3_ACCESS_KEY" \
        -e CHECK_S3_SECRET_KEY="$S3_SECRET_KEY" \
        -e CHECK_S3_REGION="${S3_REGION:-us-east-1}" \
        -e CHECK_S3_BUCKET="$S3_BUCKET_NAME" \
        "$BACKEND_CONTAINER" /home/frappe/frappe-bench/env/bin/python -c '
import os
import boto3

client = boto3.client(
    "s3",
    endpoint_url=os.environ["CHECK_S3_ENDPOINT"],
    aws_access_key_id=os.environ["CHECK_S3_ACCESS_KEY"],
    aws_secret_access_key=os.environ["CHECK_S3_SECRET_KEY"],
    region_name=os.environ["CHECK_S3_REGION"],
)
client.head_bucket(Bucket=os.environ["CHECK_S3_BUCKET"])
' >/dev/null 2>&1; then
        check_pass "S3 endpoint and bucket are reachable."
    else
        check_fail "S3 endpoint or bucket preflight failed."
    fi
}

get_site_config() {
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" show-config 2>/dev/null
}

get_config_value() {
    local config="$1"
    local key="$2"

    if printf '%s' "$config" | jq -e . >/dev/null 2>&1; then
        printf '%s' "$config" | jq -r --arg key "$key" '.[$key] // empty'
        return
    fi

    printf '%s\n' "$config" | awk -F '|' -v wanted="$key" '
        {
            key = $2
            value = $3
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
            if (key == wanted) {
                print value
                exit
            }
        }
    '
}

get_traceback_setting() {
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" execute \
        frappe.db.get_single_value \
        --args '["System Settings", "allow_error_traceback"]' 2>/dev/null |
        tr -d '[:space:]"'
}

verify_production_state() {
    local config
    local developer_mode
    local allow_tests
    local host_name
    local traceback_setting

    echo "Verifying Frappe production settings..."
    if ! config=$(get_site_config); then
        check_fail "Could not read the merged Frappe site configuration."
        return
    fi

    developer_mode=$(get_config_value "$config" developer_mode)
    allow_tests=$(get_config_value "$config" allow_tests)
    host_name=$(get_config_value "$config" host_name)

    case "$developer_mode" in
        ""|0|false|False) check_pass "developer_mode is disabled." ;;
        *) check_fail "developer_mode is not disabled." ;;
    esac

    case "$allow_tests" in
        ""|0|false|False) check_pass "allow_tests is disabled." ;;
        *) check_fail "allow_tests is not disabled." ;;
    esac

    if [ "$host_name" = "${PUBLIC_URL:-}" ]; then
        check_pass "Frappe host_name matches PUBLIC_URL."
    else
        check_fail "Frappe host_name does not match PUBLIC_URL."
    fi

    traceback_setting=$(get_traceback_setting || true)
    case "$traceback_setting" in
        0|False|false|None|null|"")
            check_pass "System Settings error tracebacks are disabled."
            ;;
        *)
            check_fail "System Settings allow_error_traceback is enabled."
            ;;
    esac
}

confirm_apply() {
    if [ "$YES" -eq 1 ]; then
        return
    fi
    if [ ! -t 0 ]; then
        echo "Error: Interactive confirmation is unavailable. Use --yes for trusted automation."
        exit 1
    fi

    echo "This will put site '$SITE_DOMAIN' into maintenance mode, create a backup,"
    echo "apply production settings, run migrations, and restart Frappe services."
    local confirmation
    if ! read -r -p "Type PRODUCTION to continue: " confirmation || [ "$confirmation" != "PRODUCTION" ]; then
        echo "Production apply cancelled."
        exit 1
    fi
}

set_system_settings() {
    docker exec -i "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" console <<'PY'
import frappe

frappe.db.set_single_value("System Settings", "allow_error_traceback", 0)
frappe.db.commit()
PY
}

apply_production_settings() {
    local rate_limit_json

    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" set-config developer_mode 0 --parse
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" set-config allow_tests 0 --parse
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" set-config host_name "$PUBLIC_URL"

    if [ -n "${FRAPPE_RATE_LIMIT:-}" ] && [ -n "${FRAPPE_RATE_LIMIT_WINDOW:-}" ]; then
        rate_limit_json=$(printf '{"limit":%s,"window":%s}' \
            "$FRAPPE_RATE_LIMIT" "$FRAPPE_RATE_LIMIT_WINDOW")
        docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" set-config \
            rate_limit "$rate_limit_json" --parse
    fi

    set_system_settings
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" enable-scheduler
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" migrate
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" clear-cache
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" clear-website-cache
    "${COMPOSE_CMD[@]}" restart backend frontend websocket queue-long queue-short scheduler
}

on_error() {
    local status=$?
    if [ "$APPLY_ACTIVE" -eq 1 ]; then
        echo "Error: Production apply failed. The site remains in maintenance mode for inspection."
        echo "Review this script log and the container logs before running:"
        echo "  docker exec $BACKEND_CONTAINER bench --site $SITE_DOMAIN set-maintenance-mode off"
    fi
    return "$status"
}

run_checks() {
    CHECK_FAILURES=0
    check_environment
    check_runtime
    check_s3
    verify_production_state

    if [ "$CHECK_FAILURES" -gt 0 ]; then
        echo "Production checks failed: $CHECK_FAILURES issue(s)."
        return 1
    fi
    echo "All production checks passed."
}

run_verify() {
    CHECK_FAILURES=0
    check_runtime
    verify_production_state
    if [ "$CHECK_FAILURES" -gt 0 ]; then
        echo "Production verification failed: $CHECK_FAILURES issue(s)."
        return 1
    fi
    echo "Production settings are verified."
}

run_apply() {
    CHECK_FAILURES=0
    check_environment
    check_runtime
    check_s3
    if [ "$CHECK_FAILURES" -gt 0 ]; then
        echo "Production preflight failed: $CHECK_FAILURES issue(s). No changes were applied."
        return 1
    fi

    confirm_apply
    APPLY_ACTIVE=1
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" set-maintenance-mode on
    "$SCRIPT_DIR/backup.sh" --yes
    apply_production_settings

    CHECK_FAILURES=0
    verify_production_state
    if [ "$CHECK_FAILURES" -gt 0 ]; then
        echo "Production verification failed. The site remains in maintenance mode."
        return 1
    fi

    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" set-maintenance-mode off
    APPLY_ACTIVE=0
    echo "Production settings applied successfully for $PUBLIC_URL"
}

main() {
    parse_args "$@"
    require_command docker
    require_command jq
    require_command grep
    load_configuration
    apply_script_log_retention "${SCRIPT_LOG_RETENTION_DAYS:-30}"
    trap on_error ERR

    case "$COMMAND" in
        check) run_checks ;;
        verify) run_verify ;;
        apply) run_apply ;;
    esac
}

main "$@"
