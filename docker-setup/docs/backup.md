# Backup Script (`backup.sh`)

> **Full guide:** [Backup Automation Guide](backup-automation-guide.md) — local backup, cron schedule, retention, and Google Drive offsite setup.

The `backup.sh` script is a crucial utility for production environments. It triggers an internal Frappe backup and copies the resulting files to the host machine for safe keeping.

## What it does

1.  **Bench Backup**: Executes the `bench backup --with-files` command inside the Frappe backend container. This creates:
    -   A SQL dump of the database.
    -   A compressed archive of public and private files.
2.  **Verification and Host Extraction**: Identifies the latest complete backup set, verifies its database, public files, private files, and site configuration files, then copies only that set to the host.
3.  **Timestamping**: Organizes backups into directories named with the date and time (`YYYY-MM-DD_HH-MM-SS`) inside a `./backups/` folder.
4.  **Retention**: After the host copy is verified, uses each timestamp folder name (`YYYY-MM-DD_HH-MM-SS`) to delete host backups older than `BACKUP_RETENTION_DAYS` (default `14`) and keeps the latest `CONTAINER_BACKUP_KEEP_COUNT` complete sets (default `3`) inside the container.

Configure retention in `.env`:

```env
BACKUP_RETENTION_DAYS=14
CONTAINER_BACKUP_KEEP_COUNT=3
```

## Usage

```bash
chmod +x backup.sh
./backup.sh
```

## Output Location

Backups are saved locally at:
`./docker-setup/backups/[TIMESTAMP]/`

## Why use this?

While Docker volumes store your data, they are not a substitute for proper backups. This script ensures you have actual files and database dumps that can be:
-   Moved to an off-site storage (S3, Dropbox, etc.).
-   Used to restore the site on a completely different server using `restore.sh`.
-   Versioned or archived for long-term data safety.
