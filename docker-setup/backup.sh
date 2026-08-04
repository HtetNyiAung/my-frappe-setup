#!/usr/bin/env bash
# Purpose: Export site database and files from the container to the host
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
init_script_logging "$SCRIPT_DIR" "backup"

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

get_latest_backup_prefix() {
    docker exec "$BACKEND_CONTAINER" sh -c '
        backup_dir="$1"
        latest_database=$(find "$backup_dir" -maxdepth 1 -type f -name "*-database.sql.gz" \
            -printf "%T@ %f\n" | sort -rn | sed -n "1{s/^[^ ]* //;p;}")
        [ -n "$latest_database" ] || exit 1
        printf "%s\n" "${latest_database%-database.sql.gz}"
    ' sh "$CONTAINER_BACKUP_DIR"
}

verify_container_backup_set() {
    local backup_prefix="$1"
    local suffix

    for suffix in database.sql.gz files.tar private-files.tar site_config_backup.json; do
        if ! docker exec "$BACKEND_CONTAINER" test -s \
            "$CONTAINER_BACKUP_DIR/$backup_prefix-$suffix"; then
            echo "Error: Backup file is missing or empty: $backup_prefix-$suffix"
            return 1
        fi
    done
}

copy_backup_set_to_host() {
    local backup_prefix="$1"
    local suffix

    mkdir -p "$HOST_BACKUP_DIR"
    for suffix in database.sql.gz files.tar private-files.tar site_config_backup.json; do
        docker cp \
            "$BACKEND_CONTAINER:$CONTAINER_BACKUP_DIR/$backup_prefix-$suffix" \
            "$HOST_BACKUP_DIR/"
    done
}

verify_host_backup_set() {
    local backup_prefix="$1"
    local suffix

    for suffix in database.sql.gz files.tar private-files.tar site_config_backup.json; do
        if [ ! -s "$HOST_BACKUP_DIR/$backup_prefix-$suffix" ]; then
            echo "Error: Host backup file is missing or empty: $backup_prefix-$suffix"
            return 1
        fi
    done
}

cleanup_container_backups() {
    local keep_count="$1"

    docker exec -i "$BACKEND_CONTAINER" sh -s -- \
        "$CONTAINER_BACKUP_DIR" "$keep_count" <<'SH'
set -eu
backup_dir="$1"
keep_count="$2"

find "$backup_dir" -maxdepth 1 -type f -name "*-database.sql.gz" \
    -printf "%T@ %f\n" | sort -rn | awk -v keep="$keep_count" '
        NR > keep { sub(/^[^ ]* /, ""); print }
    ' | while IFS= read -r database_file; do
        [ -n "$database_file" ] || continue
        backup_prefix="${database_file%-database.sql.gz}"
        for suffix in database.sql.gz files.tar private-files.tar site_config_backup.json; do
            backup_file="$backup_dir/$backup_prefix-$suffix"
            if [ -f "$backup_file" ]; then
                echo "  removing container backup file: $backup_prefix-$suffix"
                rm -f -- "$backup_file"
            fi
        done
    done
SH
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
apply_script_log_retention "${SCRIPT_LOG_RETENTION_DAYS:-30}"

RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"
CONTAINER_KEEP_COUNT="${CONTAINER_BACKUP_KEEP_COUNT:-3}"
CONTAINER_BACKUP_DIR="/home/frappe/frappe-bench/sites/$SITE_DOMAIN/private/backups"

# Create a timestamped directory for the backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_PATH="./backups/$TIMESTAMP"
HOST_BACKUP_DIR="$BACKUP_PATH/backups"

echo "=========================================="
echo "Backing up Site: $SITE_DOMAIN"
echo "=========================================="

# 1. Trigger the internal bench backup command
repair_db_credentials
docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" backup --with-files

# 2. Verify and copy only the backup set created most recently
LATEST_BACKUP_PREFIX=$(get_latest_backup_prefix)
echo "Verifying backup set: $LATEST_BACKUP_PREFIX"
verify_container_backup_set "$LATEST_BACKUP_PREFIX"

echo "Copying backup files to $HOST_BACKUP_DIR..."
copy_backup_set_to_host "$LATEST_BACKUP_PREFIX"
verify_host_backup_set "$LATEST_BACKUP_PREFIX"

echo "Backup Complete. Files saved in $BACKUP_PATH"

# 3. Host retention: remove timestamp folders older than the configured days
if ! [[ "$RETENTION_DAYS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Warning: BACKUP_RETENTION_DAYS ('$RETENTION_DAYS') must be a positive integer; skipping host cleanup."
else
    echo "Applying retention: deleting backups older than $RETENTION_DAYS day(s)..."
    retention_cutoff=$(date -d "$RETENTION_DAYS days ago" +%s)
    while IFS= read -r -d '' backup_dir; do
        folder_name="${backup_dir##*/}"
        if [[ ! "$folder_name" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})_([0-9]{2})-([0-9]{2})-([0-9]{2})$ ]]; then
            echo "  skipping folder with an unsupported name: $backup_dir"
            continue
        fi

        folder_date="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}:${BASH_REMATCH[3]}:${BASH_REMATCH[4]}"
        if ! folder_timestamp=$(date -d "$folder_date" +%s 2>/dev/null); then
            echo "  skipping folder with an invalid timestamp: $backup_dir"
            continue
        fi

        if [ "$folder_timestamp" -lt "$retention_cutoff" ]; then
            echo "  removing $backup_dir"
            rm -rf -- "$backup_dir"
        fi
    done < <(find ./backups -mindepth 1 -maxdepth 1 -type d -print0)
    echo "Retention cleanup complete."
fi

# 4. Container retention: keep the latest complete backup sets
if ! [[ "$CONTAINER_KEEP_COUNT" =~ ^[1-9][0-9]*$ ]]; then
    echo "Warning: CONTAINER_BACKUP_KEEP_COUNT ('$CONTAINER_KEEP_COUNT') must be a positive integer; skipping container cleanup."
else
    echo "Keeping the latest $CONTAINER_KEEP_COUNT backup set(s) in the container..."
    cleanup_container_backups "$CONTAINER_KEEP_COUNT"
    echo "Container retention cleanup complete."
fi
