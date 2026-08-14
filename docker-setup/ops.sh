#!/usr/bin/env bash
# Purpose: Day-to-day operations for an existing Frappe stack.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
# shellcheck source=lib/runtime.sh
source "$SCRIPT_DIR/lib/runtime.sh"

COMMAND=""
YES=0
FOLLOW=0
TAIL=100
SERVICE=""
MIGRATE_ACTIVE=0

usage() {
    cat <<'EOF'
Usage: ./ops.sh <command> [options]

Commands:
  status                    Show Compose services and verify the Frappe site.
  restart                   Restart Frappe application services.
  clear-cache               Clear site and website caches.
  migrate                   Back up, migrate, clear caches, and verify safely.
  logs [service]            Show logs (all services if service is omitted).
  maintenance-on            Enable Maintenance Mode.
  maintenance-off           Disable Maintenance Mode after manual recovery.

Options:
  --follow, -f              Follow logs continuously.
  --tail N                  Number of log lines to show (default: 100).
  --yes, -y                 Skip confirmation for trusted automation.
  --help, -h                Show this help message.
EOF
}

parse_args() {
    if [ "$#" -eq 0 ]; then
        usage
        exit 1
    fi
    COMMAND="$1"
    shift

    case "$COMMAND" in
        status|restart|clear-cache|migrate|logs|maintenance-on|maintenance-off) ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Error: Unknown command: $COMMAND"; usage; exit 1 ;;
    esac

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --yes|-y) YES=1 ;;
            --follow|-f) FOLLOW=1 ;;
            --tail)
                shift
                [ "$#" -gt 0 ] || { echo "Error: --tail requires a number."; exit 1; }
                TAIL="$1"
                ;;
            --help|-h) usage; exit 0 ;;
            *)
                if [ "$COMMAND" = "logs" ] && [ -z "$SERVICE" ]; then
                    SERVICE="$1"
                else
                    echo "Error: Unexpected argument: $1"
                    exit 1
                fi
                ;;
        esac
        shift
    done

    [[ "$TAIL" =~ ^[0-9]+$ ]] || { echo "Error: --tail must be a non-negative integer."; exit 1; }
}

require_runtime() {
    runtime_require_command docker
    docker info >/dev/null 2>&1 || {
        echo "Error: Docker daemon is unavailable to the current user."
        return 1
    }
    runtime_validate_compose
}

on_exit() {
    local status=$?
    if [ "$status" -ne 0 ] && [ "$MIGRATE_ACTIVE" -eq 1 ]; then
        echo "Migration failed. Maintenance Mode remains enabled and background writers remain stopped."
        echo "Inspect logs before recovery: ./ops.sh logs backend"
    fi
    script_logging_finish "$status"
    exit "$status"
}

run_migrate() {
    echo "This will enable Maintenance Mode, stop workers, create a verified backup, and migrate '$SITE_DOMAIN'."
    runtime_confirm MIGRATE "Type MIGRATE to continue: " "$YES"
    runtime_acquire_lock migrate
    runtime_verify

    MIGRATE_ACTIVE=1
    runtime_set_maintenance on
    runtime_stop_writers
    "$SCRIPT_DIR/backup.sh" --yes
    runtime_bench_site migrate
    runtime_clear_caches
    runtime_start_writers
    runtime_restart_frappe
    runtime_wait_for_backend
    runtime_verify
    runtime_set_maintenance off
    MIGRATE_ACTIVE=0
    echo "Migration completed successfully."
}

run_logs() {
    local args=(logs --tail "$TAIL")
    [ "$FOLLOW" -eq 1 ] && args+=(-f)
    [ -n "$SERVICE" ] && args+=("$SERVICE")
    runtime_compose "${args[@]}"
}

main() {
    parse_args "$@"
    if [ "$COMMAND" = "logs" ]; then
        # Do not duplicate an unbounded followed Docker log stream to disk.
        init_script_logging "$SCRIPT_DIR" "ops" "metadata"
    else
        init_script_logging "$SCRIPT_DIR" "ops"
    fi
    runtime_load_configuration "$SCRIPT_DIR"
    apply_script_log_retention "${SCRIPT_LOG_RETENTION_DAYS:-30}"
    trap on_exit EXIT
    require_runtime

    case "$COMMAND" in
        status) runtime_compose ps; runtime_verify ;;
        restart)
            runtime_confirm RESTART "Type RESTART to continue: " "$YES"
            runtime_acquire_lock restart
            runtime_restart_frappe
            runtime_wait_for_backend
            runtime_verify
            ;;
        clear-cache)
            runtime_acquire_lock clear-cache
            runtime_clear_caches
            ;;
        migrate) run_migrate ;;
        logs) run_logs ;;
        maintenance-on)
            runtime_confirm MAINTENANCE "Type MAINTENANCE to continue: " "$YES"
            runtime_acquire_lock maintenance-on
            runtime_set_maintenance on
            ;;
        maintenance-off)
            runtime_confirm RECOVERED "Type RECOVERED to disable Maintenance Mode: " "$YES"
            runtime_acquire_lock maintenance-off
            runtime_set_maintenance off
            ;;
    esac
}

main "$@"
