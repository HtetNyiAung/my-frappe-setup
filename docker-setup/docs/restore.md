# Restore Script (`restore.sh`)

The `restore.sh` script restores a Frappe backup into the site configured in `.env`.

It is intended for production use only when you understand that restore is destructive.

## What It Restores

- Database backup: `*database.sql.gz`
- Public files backup: `*files.tar`
- Private files backup: `*private-files.tar`

The script searches inside the folder you pass, so both of these paths work:

```bash
./restore.sh ./backups/2026-05-14_06-37-00
./restore.sh ./backups/2026-05-14_06-37-00/backups
```

## What It Does

1. Loads `.env` from the `docker-setup` folder.
2. Validates required values:
   - `BACKEND_CONTAINER`
   - `SITE_DOMAIN`
3. Confirms that the backend container is running.
4. Finds the database, public files, and private files backup archives.
5. Asks for confirmation unless `--yes` is used.
6. Creates a safety backup before restore unless `--skip-pre-backup` is used.
7. Uploads backup files into temporary container storage.
8. Runs `bench restore` with public and private file restore flags.
9. Runs `bench migrate`.
10. Clears Frappe cache and website cache.
11. Removes temporary restore files from the container.

## Usage

Interactive production restore:

```bash
cd docker-setup
./restore.sh ./backups/2026-05-14_06-37-00/backups
```

Non-interactive restore:

```bash
cd docker-setup
./restore.sh --yes ./backups/2026-05-14_06-37-00/backups
```

Restore without automatic pre-restore backup:

```bash
cd docker-setup
./restore.sh --skip-pre-backup ./backups/2026-05-14_06-37-00/backups
```

Use `--skip-pre-backup` only when the current site is broken and cannot be backed up.

## Important Warning

This script is destructive. It overwrites the existing database for the site defined by `SITE_DOMAIN` in `.env`.

Before restoring production, confirm:

- You are on the correct server.
- `.env` points to the correct site.
- The backup folder is from the site you want to restore.
- The backup includes database, public files, and private files.
- You have enough disk space for the restore and safety backup.

## Prerequisites

- Frappe containers must be running.
- `BACKEND_CONTAINER` in `.env` must be correct.
- `SITE_DOMAIN` in `.env` must match the target site.
- The backup folder must contain a `*database.sql.gz` file.

## Backup Folder Example

Expected files:

```text
20260514_130702-frontend-database.sql.gz
20260514_130702-frontend-files.tar
20260514_130702-frontend-private-files.tar
20260514_130702-frontend-site_config_backup.json
```

The `site_config_backup.json` file is kept for reference. The script does not automatically overwrite the current `site_config.json`, because doing so can break database credentials on the target server.
