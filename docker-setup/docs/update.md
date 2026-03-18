# Update Script (`update.sh`)

The `update.sh` script is designed to safely update your Frappe Framework and installed Applications (ERPNext, HRMS, Insights) to their latest versions or to new branches.

## What it does

1.  **Safety Backup**: Automatically runs `./backup.sh` before doing anything else. If something goes wrong during the update, your data is safe.
2.  **App Sync**: Puls the latest changes from the `frappe_docker` repository.
3.  **Image Reconstruction**: Rebuilds your `CUSTOM_IMAGE` using the current `apps.json` and `FRAPPE_BRANCH`. This ensures all new code is fetched from GitHub.
4.  **Database Migration**: Restarts the containers and runs `bench migrate` to update your database schema to match the new code.

## Usage

```bash
chmod +x update.sh
./update.sh
```

## When to use this?

-   When you want to pull the **latest bug fixes** from ERPNext or Frappe.
-   When you change a **branch** in `apps.json` (e.g., from `version-15` to `version-16`).
-   When you want to ensure your Docker image is perfectly synced with the remote repositories.

## Workflow for Version Upgrades

If you want to upgrade from Version 15 to Version 16:
1.  Open `.env` and change `FRAPPE_BRANCH=version-16`.
2.  Open `apps.json` and change all app branches to `version-16`.
3.  Run `./update.sh`.
