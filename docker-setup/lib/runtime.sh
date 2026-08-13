#!/usr/bin/env bash
# Shared runtime helpers for deploy.sh and ops.sh.

runtime_require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: Required command '$1' is not installed or not in PATH."
        return 1
    fi
}

runtime_is_truthy() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

runtime_load_configuration() {
    local base_dir="$1"

    if [ ! -f "$base_dir/.env" ]; then
        echo "Error: $base_dir/.env does not exist. Run setup.sh for first-time setup."
        return 1
    fi

    set -a
    # shellcheck disable=SC1091
    source "$base_dir/.env"
    set +a

    : "${COMPOSE_FILE:?COMPOSE_FILE is required in .env}"
    : "${CUSTOM_IMAGE:?CUSTOM_IMAGE is required in .env}"
    : "${SITE_DOMAIN:?SITE_DOMAIN is required in .env}"

    if [ ! -f "$base_dir/$COMPOSE_FILE" ]; then
        echo "Error: Compose file '$COMPOSE_FILE' was not found in $base_dir."
        return 1
    fi

    RUNTIME_COMPOSE_CMD=(docker compose -f "$COMPOSE_FILE")
    if [ -f "$base_dir/docker-compose.override.yml" ]; then
        RUNTIME_COMPOSE_CMD+=(-f docker-compose.override.yml)
    fi
}

runtime_compose() {
    "${RUNTIME_COMPOSE_CMD[@]}" "$@"
}

runtime_backend_exec() {
    runtime_compose exec -T backend "$@"
}

runtime_bench_site() {
    runtime_backend_exec bench --site "$SITE_DOMAIN" "$@"
}

runtime_confirm() {
    local expected="$1"
    local prompt="$2"
    local assume_yes="${3:-0}"
    local answer

    if [ "$assume_yes" -eq 1 ]; then
        return 0
    fi
    if [ ! -t 0 ]; then
        echo "Error: Interactive confirmation is unavailable. Use --yes for trusted automation."
        return 1
    fi
    if ! read -r -p "$prompt" answer || [ "$answer" != "$expected" ]; then
        echo "Operation cancelled."
        return 1
    fi
}

runtime_acquire_lock() {
    local operation="$1"
    local safe_stack_id

    runtime_require_command flock
    safe_stack_id="${STACK_ID:-frappe-stack}"
    safe_stack_id="${safe_stack_id//[^a-zA-Z0-9_.-]/_}"
    RUNTIME_LOCK_FILE="${DEPLOY_LOCK_FILE:-/tmp/${safe_stack_id}-deployment.lock}"

    exec 9>"$RUNTIME_LOCK_FILE"
    if ! flock -n 9; then
        echo "Error: Another deployment or migration is active (lock: $RUNTIME_LOCK_FILE)."
        return 1
    fi
    printf '%s\n' "operation=$operation pid=$$ started=$(date --iso-8601=seconds)" >&9
}

runtime_validate_compose() {
    if ! runtime_compose config >/dev/null; then
        echo "Error: Docker Compose configuration is invalid."
        return 1
    fi
}

runtime_backend_is_running() {
    [ -n "$(runtime_compose ps -q --status running backend 2>/dev/null)" ]
}

runtime_site_exists() {
    runtime_backend_exec bench list-sites 2>/dev/null |
        awk 'NF {print $NF}' |
        grep -Fxq "$SITE_DOMAIN"
}

runtime_wait_for_backend() {
    local attempt
    local max_attempts="${1:-24}"

    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        if runtime_backend_exec bench list-sites >/dev/null 2>&1; then
            echo "Backend is ready."
            return 0
        fi
        echo "Waiting for backend ($attempt/$max_attempts)..."
        sleep 5
    done

    echo "Error: Backend did not become ready in time."
    return 1
}

runtime_wait_for_service() {
    local attempt
    local container_id
    local health
    local max_attempts="${2:-24}"
    local service="$1"

    for ((attempt = 1; attempt <= max_attempts; attempt++)); do
        container_id="$(runtime_compose ps -q --status running "$service" 2>/dev/null)"
        if [ -n "$container_id" ]; then
            health="$(docker inspect --format \
                '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
                "$container_id" 2>/dev/null || true)"
            case "$health" in
                healthy|none)
                    echo "Service '$service' is ready."
                    return 0
                    ;;
            esac
        fi
        echo "Waiting for service '$service' ($attempt/$max_attempts)..."
        sleep 5
    done

    echo "Error: Service '$service' did not become ready in time."
    return 1
}

runtime_set_maintenance() {
    local mode="$1"
    runtime_bench_site set-maintenance-mode "$mode"
}

runtime_stop_writers() {
    runtime_compose stop scheduler queue-long queue-short
}

runtime_start_writers() {
    runtime_compose up -d queue-long queue-short scheduler
}

runtime_clear_caches() {
    runtime_bench_site clear-cache
    runtime_bench_site clear-website-cache
}

runtime_restart_frappe() {
    runtime_compose restart backend frontend websocket queue-long queue-short scheduler
}

runtime_verify() {
    local container_id
    local failures=0
    local health
    local service

    for service in backend frontend queue-long queue-short scheduler websocket; do
        container_id="$(runtime_compose ps -q --status running "$service" 2>/dev/null)"
        if [ -z "$container_id" ]; then
            echo "[FAIL] Service '$service' is not running."
            failures=$((failures + 1))
            continue
        fi

        health="$(docker inspect --format \
            '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
            "$container_id" 2>/dev/null || true)"
        if [ "$health" = "unhealthy" ]; then
            echo "[FAIL] Service '$service' is running but unhealthy."
            failures=$((failures + 1))
        else
            echo "[PASS] Service '$service' is running (health: $health)."
        fi
    done

    if runtime_site_exists; then
        echo "[PASS] Site '$SITE_DOMAIN' exists."
    else
        echo "[FAIL] Site '$SITE_DOMAIN' is not available."
        failures=$((failures + 1))
    fi

    if runtime_bench_site list-apps >/dev/null 2>&1; then
        echo "[PASS] Site database connection works."
    else
        echo "[FAIL] Site database connection failed."
        failures=$((failures + 1))
    fi

    [ "$failures" -eq 0 ]
}
