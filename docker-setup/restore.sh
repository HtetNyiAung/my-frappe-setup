#!/usr/bin/env bash
# Purpose: Restore a Frappe backup into the configured site.
# Usage: ./restore.sh [--yes] [--skip-pre-backup] <path_to_backup_folder>
set -Eeuo pipefail

CALL_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

YES=0
SKIP_PRE_BACKUP=0
BACKUP_SRC=""
RESTORE_DIR="/tmp/restore_data_$(date +%Y%m%d_%H%M%S)"

usage() {
    cat <<'EOF'
Usage:
  ./restore.sh [--yes] [--skip-pre-backup] <path_to_backup_folder>

Examples:
  ./restore.sh ./backups/2026-05-14_06-37-00
  ./restore.sh ./backups/2026-05-14_06-37-00/backups
  ./restore.sh --yes ./backups/2026-05-14_06-37-00/backups

Options:
  --yes              Do not ask for interactive confirmation.
  --skip-pre-backup  Do not create a safety backup before restoring.

Warning:
  Restore is destructive. It overwrites the current site database.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --yes|-y)
            YES=1
            shift
            ;;
        --skip-pre-backup)
            SKIP_PRE_BACKUP=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        -*)
            echo "Error: Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [ -n "$BACKUP_SRC" ]; then
                echo "Error: Only one backup folder path is allowed."
                usage
                exit 1
            fi
            BACKUP_SRC="$1"
            shift
            ;;
    esac
done

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: Required command '$1' is not installed or not in PATH."
        exit 1
    fi
}

load_env() {
    set -a
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
    local status=$?
    set +a
    return "$status"
}

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

cleanup() {
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -Fxq "${BACKEND_CONTAINER:-}"; then
        docker exec "$BACKEND_CONTAINER" rm -rf "$RESTORE_DIR" >/dev/null 2>&1 || true
    fi
}

find_first() {
    local folder="$1"
    shift
    find "$folder" "$@" -print -quit
}

require_command docker
require_command find

if [ -f "$SCRIPT_DIR/.env" ]; then
    if ! load_env; then
        echo "Error: Failed to load $SCRIPT_DIR/.env. Check for invalid shell syntax."
        exit 1
    fi
else
    echo "Error: .env file missing. Restore aborted."
    exit 1
fi

require_env BACKEND_CONTAINER SITE_DOMAIN

if [ -z "$BACKUP_SRC" ]; then
    echo "Error: Backup folder path is required."
    usage
    exit 1
fi

if [ ! -d "$BACKUP_SRC" ]; then
    if [ -d "$CALL_DIR/$BACKUP_SRC" ]; then
        BACKUP_SRC="$CALL_DIR/$BACKUP_SRC"
    else
        echo "Error: Backup directory $BACKUP_SRC not found."
        exit 1
    fi
fi

if ! docker ps --format '{{.Names}}' | grep -Fxq "$BACKEND_CONTAINER"; then
    echo "Error: Backend container '$BACKEND_CONTAINER' is not running."
    exit 1
fi

SQL_FILE=$(find_first "$BACKUP_SRC" -type f -name "*database.sql.gz")
PUBLIC_FILES=$(find_first "$BACKUP_SRC" -type f -name "*files.tar" ! -name "*private-files.tar")
PRIVATE_FILES=$(find_first "$BACKUP_SRC" -type f -name "*private-files.tar")

if [ -z "$SQL_FILE" ]; then
    echo "Error: No database backup file matching '*database.sql.gz' found in $BACKUP_SRC"
    exit 1
fi

echo "=========================================="
echo "Restore Target Site: $SITE_DOMAIN"
echo "Source Folder:       $BACKUP_SRC"
echo "Database Backup:     $SQL_FILE"
echo "Public Files:        ${PUBLIC_FILES:-not found}"
echo "Private Files:       ${PRIVATE_FILES:-not found}"
echo "=========================================="

if [ -z "$PUBLIC_FILES" ] || [ -z "$PRIVATE_FILES" ]; then
    echo "Warning: Public and/or private file backup tar was not found."
    echo "The database can still be restored, but uploaded PDFs/images/files may be missing."
fi

if [ "$YES" -ne 1 ]; then
    echo
    echo "This restore will overwrite the current database for site '$SITE_DOMAIN'."
    read -r -p "Type RESTORE to continue: " CONFIRM
    if [ "$CONFIRM" != "RESTORE" ]; then
        echo "Restore cancelled."
        exit 1
    fi
fi

if [ "$SKIP_PRE_BACKUP" -ne 1 ]; then
    echo "Creating safety backup before restore..."
    "$SCRIPT_DIR/backup.sh"
else
    echo "Skipping pre-restore safety backup because --skip-pre-backup was provided."
fi

trap cleanup EXIT

echo "Uploading backup files to container temporary storage..."
docker exec "$BACKEND_CONTAINER" rm -rf "$RESTORE_DIR"
docker exec "$BACKEND_CONTAINER" mkdir -p "$RESTORE_DIR"
docker cp "$BACKUP_SRC/." "$BACKEND_CONTAINER":"$RESTORE_DIR"/

INTERNAL_SQL_PATH=$(docker exec "$BACKEND_CONTAINER" find "$RESTORE_DIR" -type f -name "*database.sql.gz" -print -quit)
INTERNAL_PUBLIC_FILES=$(docker exec "$BACKEND_CONTAINER" find "$RESTORE_DIR" -type f -name "*files.tar" ! -name "*private-files.tar" -print -quit)
INTERNAL_PRIVATE_FILES=$(docker exec "$BACKEND_CONTAINER" find "$RESTORE_DIR" -type f -name "*private-files.tar" -print -quit)

RESTORE_ARGS=(--site "$SITE_DOMAIN" restore "$INTERNAL_SQL_PATH" --force)

if [ -n "$INTERNAL_PUBLIC_FILES" ]; then
    RESTORE_ARGS+=(--with-public-files "$INTERNAL_PUBLIC_FILES")
fi

if [ -n "$INTERNAL_PRIVATE_FILES" ]; then
    RESTORE_ARGS+=(--with-private-files "$INTERNAL_PRIVATE_FILES")
fi

echo "Running bench restore. This will overwrite current site data..."
docker exec -i "$BACKEND_CONTAINER" bench "${RESTORE_ARGS[@]}"

echo "Finalizing restore and syncing schema..."
docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" migrate
docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" clear-cache
docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" clear-website-cache

echo "=========================================="
echo "RESTORE COMPLETE"
echo "Site $SITE_DOMAIN has been restored."
echo "A pre-restore safety backup was created unless --skip-pre-backup was used."
echo "=========================================="
