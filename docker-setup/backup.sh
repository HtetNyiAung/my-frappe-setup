#!/usr/bin/env bash
# Purpose: Export site database and files from the container to the host
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# shellcheck source=lib/logging.sh
source "$SCRIPT_DIR/lib/logging.sh"
init_script_logging "$SCRIPT_DIR" "backup"

YES=0

usage() {
    cat <<'EOF'
Usage: ./backup.sh [--yes]

Options:
  --yes, -y  Run without interactive confirmation (for cron or trusted scripts).
  --help, -h Show this help message.
EOF
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
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

is_truthy() {
    case "${1:-}" in
        true|TRUE|True|1|yes|YES|Yes|on|ON|On)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

confirm_backup() {
    if [ "$YES" -eq 1 ]; then
        return
    fi

    if [ ! -t 0 ]; then
        echo "Error: Interactive confirmation is unavailable. Use --yes for trusted automation."
        exit 1
    fi

    echo "This will create a database and file backup for site '$SITE_DOMAIN'."
    if is_truthy "${S3_STORAGE_ENABLED:-false}" && is_truthy "${S3_BACKUP_UPLOAD_ENABLED:-false}"; then
        echo "The verified backup set will also be uploaded to S3 bucket '$S3_BACKUP_BUCKET_NAME'."
    fi

    local confirmation
    if ! read -r -p "Type BACKUP to continue: " confirmation; then
        echo "Backup cancelled."
        exit 1
    fi
    if [ "$confirmation" != "BACKUP" ]; then
        echo "Backup cancelled."
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

upload_backup_set_to_s3() {
    local backup_prefix="$1"
    local backup_timestamp="$2"

    if ! is_truthy "${S3_STORAGE_ENABLED:-false}" || ! is_truthy "${S3_BACKUP_UPLOAD_ENABLED:-false}"; then
        echo "S3 backup upload is disabled."
        return 0
    fi

    require_env \
        S3_ENDPOINT_URL \
        S3_ACCESS_KEY \
        S3_SECRET_KEY \
        S3_REGION \
        S3_BACKUP_BUCKET_NAME

    echo "Uploading backup set to S3 bucket '$S3_BACKUP_BUCKET_NAME'..."
    docker exec -i \
        -e S3_ENDPOINT_URL="$S3_ENDPOINT_URL" \
        -e S3_ACCESS_KEY="$S3_ACCESS_KEY" \
        -e S3_SECRET_KEY="$S3_SECRET_KEY" \
        -e S3_REGION="$S3_REGION" \
        -e S3_BACKUP_BUCKET_NAME="$S3_BACKUP_BUCKET_NAME" \
        -e S3_BACKUP_PREFIX="${S3_BACKUP_PREFIX:-frappe-backups}" \
        -e S3_BACKUP_RETENTION_DAYS="${S3_BACKUP_RETENTION_DAYS:-}" \
        "$BACKEND_CONTAINER" \
        /home/frappe/frappe-bench/env/bin/python - \
        "$CONTAINER_BACKUP_DIR" \
        "$backup_prefix" \
        "$SITE_DOMAIN" \
        "$backup_timestamp" <<'PY'
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

import boto3
from botocore.exceptions import ClientError

backup_dir = Path(sys.argv[1])
backup_prefix = sys.argv[2]
site_domain = sys.argv[3]
backup_timestamp = sys.argv[4]

bucket = os.environ["S3_BACKUP_BUCKET_NAME"]
key_prefix = os.environ.get("S3_BACKUP_PREFIX", "frappe-backups").strip("/") or "frappe-backups"
object_prefix = f"{key_prefix}/{site_domain}/{backup_timestamp}"
suffixes = (
    "database.sql.gz",
    "files.tar",
    "private-files.tar",
    "site_config_backup.json",
)

client = boto3.client(
    "s3",
    endpoint_url=os.environ["S3_ENDPOINT_URL"],
    aws_access_key_id=os.environ["S3_ACCESS_KEY"],
    aws_secret_access_key=os.environ["S3_SECRET_KEY"],
    region_name=os.environ["S3_REGION"],
)

try:
    client.head_bucket(Bucket=bucket)
except ClientError as exc:
    raise SystemExit(f"S3 backup bucket is not reachable: {bucket}: {exc}") from exc

for suffix in suffixes:
    file_path = backup_dir / f"{backup_prefix}-{suffix}"
    if not file_path.is_file() or file_path.stat().st_size <= 0:
        raise SystemExit(f"Backup file is missing or empty: {file_path.name}")

    key = f"{object_prefix}/{file_path.name}"
    client.upload_file(str(file_path), bucket, key)

    remote_size = client.head_object(Bucket=bucket, Key=key)["ContentLength"]
    local_size = file_path.stat().st_size
    if remote_size != local_size:
        raise SystemExit(
            f"S3 object size mismatch for {key}: local={local_size} remote={remote_size}"
        )
    print(f"  uploaded s3://{bucket}/{key}")

retention_days = os.environ.get("S3_BACKUP_RETENTION_DAYS", "").strip()
if retention_days:
    if not retention_days.isdigit() or int(retention_days) <= 0:
        raise SystemExit(
            f"S3_BACKUP_RETENTION_DAYS must be a positive integer: {retention_days}"
        )

    cutoff = datetime.now() - timedelta(days=int(retention_days))
    site_prefix = f"{key_prefix}/{site_domain}/"
    paginator = client.get_paginator("list_objects_v2")

    for page in paginator.paginate(Bucket=bucket, Prefix=site_prefix, Delimiter="/"):
        for common_prefix in page.get("CommonPrefixes", []):
            prefix = common_prefix.get("Prefix", "")
            folder_name = prefix.rstrip("/").rsplit("/", 1)[-1]
            try:
                folder_time = datetime.strptime(folder_name, "%Y-%m-%d_%H-%M-%S")
            except ValueError:
                print(f"  skipping unsupported S3 backup prefix: {prefix}")
                continue
            if folder_time >= cutoff:
                continue

            delete_batch = []
            for object_page in paginator.paginate(Bucket=bucket, Prefix=prefix):
                delete_batch.extend(
                    {"Key": item["Key"]} for item in object_page.get("Contents", [])
                )
                while len(delete_batch) >= 1000:
                    client.delete_objects(
                        Bucket=bucket,
                        Delete={"Objects": delete_batch[:1000]},
                    )
                    delete_batch = delete_batch[1000:]
            if delete_batch:
                client.delete_objects(Bucket=bucket, Delete={"Objects": delete_batch})
            print(f"  removed expired S3 backup prefix: {prefix}")
PY
    echo "S3 backup upload complete."
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

parse_args "$@"
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
confirm_backup

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

upload_backup_set_to_s3 "$LATEST_BACKUP_PREFIX" "$TIMESTAMP"

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
