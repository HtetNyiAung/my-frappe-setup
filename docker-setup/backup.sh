#!/usr/bin/env bash
# Purpose: Export site database and files from the container to the host
set -e

# --- 1. Load Environment Variables ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | xargs)
else 
    echo "Error: .env file missing."; exit 1
fi

# Create a timestamped directory for the backup
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_PATH="./backups/$TIMESTAMP"
mkdir -p "$BACKUP_PATH"

echo "=========================================="
echo "Backing up Site: $SITE_DOMAIN"
echo "=========================================="

# 1. Trigger the internal bench backup command
docker exec "$BACKEND_CONTAINER" bench --site "$SITE_DOMAIN" backup --with-files

# 2. Copy the generated files to the host machine
echo "Copying backup files to $BACKUP_PATH..."
docker cp "$BACKEND_CONTAINER":/home/frappe/frappe-bench/sites/"$SITE_DOMAIN"/private/backups/ "$BACKUP_PATH/"

echo "Backup Complete. Files saved in $BACKUP_PATH"