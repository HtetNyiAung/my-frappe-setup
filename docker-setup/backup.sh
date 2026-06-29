#!/usr/bin/env bash
# Purpose: Export site database and files from the container to the host
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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

repair_db_credentials() {
    echo "Checking site database credentials..."
    if docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" list-apps >/dev/null 2>&1; then
        echo "Site database credentials are OK."
        return 0
    fi

    echo "Site database login failed. Repairing MariaDB user from site_config.json..."
    docker cp "$SCRIPT_DIR/repair_db_credentials.py" "$BACKEND_CONTAINER":/tmp/repair_db_credentials.py
    docker exec "$BACKEND_CONTAINER" /home/frappe/frappe-bench/env/bin/python /tmp/repair_db_credentials.py "$SITE_DOMAIN"
    docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" list-apps >/dev/null
}

require_command docker

# --- 1. Load Environment Variables ---
if [ -f "$SCRIPT_DIR/.env" ]; then
    if ! load_env; then
        echo "Error: Failed to load $SCRIPT_DIR/.env. Check for invalid shell syntax."
        exit 1
    fi
else
    echo "Error: .env file missing."
    exit 1
fi

require_env BACKEND_CONTAINER SITE_DOMAIN

# Create a timestamped directory for the backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_PATH="./backups/$TIMESTAMP"
mkdir -p "$BACKUP_PATH"

echo "=========================================="
echo "Backing up Site: $SITE_DOMAIN"
echo "=========================================="

# 1. Trigger the internal bench backup command
repair_db_credentials
docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" backup --with-files

# 2. Copy the generated files to the host machine
echo "Copying backup files to $BACKUP_PATH..."
docker cp "$BACKEND_CONTAINER":/home/frappe/frappe-bench/sites/"$SITE_DOMAIN"/private/backups/ "$BACKUP_PATH/"

echo "Backup Complete. Files saved in $BACKUP_PATH"

# 3. Retention: remove backup folders older than BACKUP_RETENTION_DAYS (default 7)
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
    echo "Warning: BACKUP_RETENTION_DAYS ('$RETENTION_DAYS') is not a number; skipping cleanup."
else
    echo "Applying retention: deleting backups older than $RETENTION_DAYS day(s)..."
    # -mtime +N matches items modified more than N*24h ago; each backup is its
    # own timestamped folder under ./backups so deleting whole dirs is safe.
    while IFS= read -r -d '' old_dir; do
        echo "  removing $old_dir"
        rm -rf "$old_dir"
    done < <(find ./backups -mindepth 1 -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" -print0)
    echo "Retention cleanup complete."
fi
