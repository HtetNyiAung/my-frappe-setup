# Backup Script (`backup.sh`)

The `backup.sh` script is a crucial utility for production environments. It triggers an internal Frappe backup and copies the resulting files to the host machine for safe keeping.

## What it does

1.  **Bench Backup**: Executes the `bench backup --with-files` command inside the Frappe backend container. This creates:
    -   A SQL dump of the database.
    -   A compressed archive of public and private files.
2.  **Host Extraction**: Automatically identifies the newly created backup files and uses `docker cp` to copy them from the container to a local directory on your server.
3.  **Timestamping**: Organizes backups into directories named with the date and time (`YYYY-MM-DD_HH-MM-SS`) inside a `./backups/` folder.

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
