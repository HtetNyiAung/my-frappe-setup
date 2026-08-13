# Frappe Docker Setup

`setup.sh` is the first-installation and infrastructure-reconfiguration script.
It builds the custom image from `apps.json`, starts Docker Compose, creates the
site, installs apps, configures storage/branding, and clears stale UI caches.
It is not the normal application update command.

## Quick Start

Run from the `docker-setup` folder:

```bash
chmod +x setup.sh deploy.sh ops.sh backup.sh restore.sh
./setup.sh
```

The script displays the target site, image, rebuild mode, and S3 mode, then
requires typing `SETUP` before it changes the stack. Trusted automation can use
`./setup.sh --yes` to skip the prompt.

Open the site:

```text
http://localhost:8787
```

## First Setup vs Later Operations

Use normal setup only when creating the stack and site for the first time:

```bash
./setup.sh
```

If the running backend already contains `SITE_DOMAIN`, a normal setup run stops
and directs you to `deploy.sh`. This prevents a daily code update from silently
running the larger provisioning workflow.

For a deliberate infrastructure reconfiguration of an existing site, use:

```bash
./setup.sh --reconfigure
```

Add `--rebuild` only when the reconfiguration also needs a fresh image:

```bash
./setup.sh --reconfigure --rebuild
```

Routine code updates use:

```bash
./deploy.sh check
./deploy.sh plan
./deploy.sh apply
```

Use `--reconfigure` when:

- Changing local/external database infrastructure settings.
- Regenerating custom app mounts or other generated Compose configuration.
- Applying setup-managed S3, public URL, or branding configuration.

See [Application Deployment Guide](../deployment/deploy.md) and
[Runtime Operations Guide](../operations/operations.md) for all later operations.

## apps.json

`apps.json` controls which Frappe apps are included in the image and installed on the site.

Current minimal example:

```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-16",
    "is_custom": false
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-16",
    "is_custom": false
  }
]
```

For normal Frappe apps, set:

```json
"is_custom": false
```

For local development/custom apps, set:

```json
"is_custom": true
```

Custom apps are cloned into:

```text
docker-setup/frappe_docker/apps/<app-name>
```

Then `setup.sh` regenerates `docker-compose.override.yml` automatically and mounts those custom apps into the required containers. You do not need to manually edit `docker-compose.override.yml` for custom apps.

### Private GitHub repositories

Keep credentials out of repository URLs. Mark a private app explicitly:

```json
{
  "name": "private_app",
  "url": "https://github.com/OWNER/private-app.git",
  "branch": "main",
  "is_custom": true,
  "private": true
}
```

Store a fine-grained GitHub token only in the ignored `.env` file:

```env
GITHUB_TOKEN=<FINE_GRAINED_GITHUB_TOKEN>
```

The token needs read-only `Contents` access to every repository marked
`private`. `setup.sh` supplies it to host-side Git operations through a
temporary HTTP authorization header. During the Docker image build it creates
a mode-`600` temporary `apps.json`, supplies that file as a BuildKit secret,
redacts the token from build output, and deletes the temporary file afterward.
Before cloning or building, setup verifies access to each configured private
repository branch with terminal credential prompts disabled. An invalid,
expired, unauthorized, or insufficiently scoped token therefore stops with a
clear error instead of asking for a username or password.

Do not use either of these credential-bearing URL forms:

```text
https://<TOKEN>@github.com/OWNER/REPOSITORY.git
https://<USERNAME>:<TOKEN>@github.com/OWNER/REPOSITORY.git
```

If a token has appeared in terminal output, a log, a screenshot, or Git
history, revoke it in GitHub and generate a replacement.

## What setup.sh Does

1. Checks required commands: `git`, `jq`, `docker`, and `python3`.
2. Loads `.env` safely.
3. Validates required environment variables.
4. Validates `apps.json`.
5. Clones `frappe_docker` if it is missing.
6. Clones custom apps from `apps.json`.
7. Regenerates `docker-compose.override.yml`.
8. Checks if the custom image already contains all apps.
9. Builds or reuses the custom image.
10. Starts Docker Compose.
11. Refreshes `sites/apps.txt`.
12. Creates the site if needed.
13. Installs apps one by one.
14. Migrates an existing site only when `--reconfigure` was explicitly given.
15. Clears stale Frappe asset cache.
16. Prints installed apps.

## Required Environment Variables

These values must exist in `.env`:

```text
CUSTOM_IMAGE
FRAPPE_BRANCH
COMPOSE_FILE
SITE_DOMAIN
ADMIN_PASSWORD
MYSQL_ROOT_PASSWORD
```

`GITHUB_TOKEN` is additionally required when `apps.json` contains an entry
with `"private": true`.

Common values:

```env
CUSTOM_IMAGE=frappe-erpnext-hrms-insights:v16
FRAPPE_BRANCH=version-16
COMPOSE_FILE=pwd-with-apps.yml
SITE_DOMAIN=frontend
FRAPPE_PORT=8787
FRAPPE_INTERNAL_PORT=8080
MYSQL_ROOT_PASSWORD=admin
MARIADB_ROOT_PASSWORD=admin
DB_ROOT_USERNAME=root
DB_NAME=
DB_PASSWORD=admin
ADMIN_PASSWORD=admin
```

Database connection and site-creation settings:

```env
DATABASE_MODE=local
DB_HOST=db
DB_PORT=3306
DB_ROOT_USERNAME=root
DB_ROOT_PASSWORD=
DB_NAME=hluttaw_lms
DB_PASSWORD=secure_site_db_password
```

- `DATABASE_MODE` — `local` for Compose MariaDB or `external` for a separate server
- `DB_HOST` / `DB_PORT` — database address reachable from the Frappe containers
- `DB_ROOT_USERNAME` — MariaDB admin user passed to `bench new-site` (default: `root`)
- `DB_ROOT_PASSWORD` — external provisioning password; local mode falls back to `MYSQL_ROOT_PASSWORD`
- `DB_NAME` — new sites only; leave empty to let Frappe derive it from `SITE_DOMAIN`
- `DB_PASSWORD` — new sites only; site database user password stored in `site_config.json`

Use [External MariaDB on an Ubuntu VM](../database/external-database-ubuntu.md) to provision
a new database host. See [External MariaDB](../database/external-database.md) before moving
an existing site. Changing `DB_HOST` does not migrate any database records.

## Database Credential Repair

Sometimes Frappe can show this error:

```text
Access denied for user '<site-db-user>'@'<container-ip>'
```

This means the password in:

```text
sites/<site>/site_config.json
```

does not match the MariaDB user password.

The setup script detects this during `list-apps`, copies
`repair_db_credentials.py` into the backend container, repairs the MariaDB user
password/grants, and retries. For an external database, repair is blocked unless
`ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=true` is explicitly configured.

Manual repair command:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml cp repair_db_credentials.py backend:/tmp/repair_db_credentials.py
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend /home/frappe/frappe-bench/env/bin/python /tmp/repair_db_credentials.py frontend
```

## Stale UI / Missing CSS Fix

If the Desk UI looks like raw HTML, the browser is usually requesting old hashed CSS files.

Example:

```text
/assets/frappe/dist/css/desk.bundle.OLDHASH.css 404
```

`setup.sh` now clears Frappe's cached `assets_json` and restarts:

```text
backend frontend websocket
```

This keeps the UI asset references synced with the current Docker image.

After setup, if the browser still shows old UI, hard refresh:

```text
Ctrl + Shift + R
```

## Docker Credential Helper Error

If Docker fails while pulling images:

```text
error getting credentials - err: exit status 1
```

Check:

```bash
cat ~/.docker/config.json
```

If it contains:

```json
{
  "credsStore": "desktop.exe"
}
```

replace it with:

```bash
cp ~/.docker/config.json ~/.docker/config.json.bak
printf '{}\n' > ~/.docker/config.json
```

Then retry:

```bash
./setup.sh
```

## Verify Setup

From `docker-setup`:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml ps
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend bench --site frontend list-apps
```

Expected installed apps:

```text
frappe
erpnext
hrms
```

## Notes

- `docker-compose.override.yml` is generated by `setup.sh`. Do not manually maintain it for custom apps.
- `docker-setup/apps.json` is passed to the image build as a BuildKit secret.
  Edit that source file rather than creating a second copy under
  `frappe_docker`.
- HRMS patch messages like `rename_field ... not found` can appear during install. If the install continues and prints the success message, those warnings are usually safe.
- `pwd-with-apps.yml` sets `restart: unless-stopped` on long-running services so containers come back after reboot or crash. Run `docker compose up -d` once after pulling this change. Also enable Docker on boot: `sudo systemctl enable docker`.
