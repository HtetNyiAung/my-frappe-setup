# Restore Script (`restore.sh`)

The `restore.sh` script is used to revert a Frappe site to a previous state using a backup folder created by `backup.sh`.

## What it does

1.  **Validation**: Verifies that the targeted backup folder exists and contains a valid SQL database dump.
2.  **Container Upload**: Uploads the backup data from your host machine into a temporary directory inside the running Frappe backend container.
3.  **Bench Restore**: Executes the `bench restore` command which:
    -   Wipes the current site database.
    -   Replaces it with the SQL dump from the backup.
4.  **Migration**: Runs `bench migrate` to ensure the restored database schema is correctly synced with the currently installed apps.
5.  **Cleanup**: Automatically removes the temporary restore files from the container storage.

## Usage

You must provide the path to the backup folder as an argument:

```bash
chmod +x restore.sh
./restore.sh ./backups/2026-03-18_03-00-00
```

## ⚠️ Important Warning

**This script is destructive.** It will completely overwrite the existing database on the site defined in your `.env`. Always ensure you have a fresh backup of your current state before running a restore.

## Prerequisites

-   The Frappe containers must be running.
-   The site name in your `.env` must match the site you are restoring to.
