#!/usr/bin/env bash
# Purpose: Restore a specific backup (SQL and Files) into the Frappe container
# Usage: ./restore.sh ./backups/YYYY-MM-DD_HH-MM-SS
set -e

# --- 1. Load Environment Variables from .env ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | xargs)
else 
    echo "Error: .env file missing. Restore aborted."; exit 1
fi

# Check if a backup directory was provided as an argument
BACKUP_SRC=$1

if [ -z "$BACKUP_SRC" ]; then
    echo "Usage: ./restore.sh <path_to_backup_folder>"
    echo "Example: ./restore.sh ./backups/2026-03-11_21-00-00"
    exit 1
fi

if [ ! -d "$BACKUP_SRC" ]; then
    echo "Error: Backup directory $BACKUP_SRC not found."
    exit 1
fi

echo "=========================================="
echo "Restoring Backup to Site: $SITE_DOMAIN"
echo "Source Folder: $BACKUP_SRC"
echo "=========================================="

# 2. Identify the SQL file inside the backup folder
# Usually ends with -database.sql.gz
SQL_FILE=$(find "$BACKUP_SRC" -name "*database.sql.gz" | head -n 1)

if [ -z "$SQL_FILE" ]; then
    echo "Error: No .sql.gz backup file found in $BACKUP_SRC"; exit 1
fi

# 3. Prepare the container for the restore
echo "Uploading backup files to container temporary storage..."
docker exec "$BACKEND_CONTAINER" mkdir -p /tmp/restore_data
docker cp "$BACKUP_SRC/." "$BACKEND_CONTAINER":/tmp/restore_data/

# 4. Execute the Bench Restore

echo "Running bench restore (this will overwrite current data)..."
SQL_BASE_NAME=$(basename "$SQL_FILE")

# We dynamically locate the SQL file inside the uploaded directory to ensure the path is foolproof
INTERNAL_SQL_PATH=$(docker exec "$BACKEND_CONTAINER" find /tmp/restore_data -name "*.sql.gz" | head -n 1)

# Execute the restore
docker exec -i "$BACKEND_CONTAINER" bash -c "bench --site '$SITE_DOMAIN' restore '$INTERNAL_SQL_PATH' --force"

# 5. Finalize with Migrations
echo "Finalizing restore and syncing schema..."
docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" migrate

# 6. Cleanup temporary files in the container
docker exec "$BACKEND_CONTAINER" rm -rf /tmp/restore_data/

echo "=========================================="
echo "✅ RESTORE COMPLETE"
echo "Site $SITE_DOMAIN has been successfully reverted."
echo "=========================================="