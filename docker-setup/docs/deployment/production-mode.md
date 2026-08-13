# Production Mode Operations

Frappe does not have one Laravel-style `APP_ENV=production` switch. This setup
uses `DEPLOYMENT_MODE=production` as an operational safety guard and applies the
individual Frappe settings required for production.

This workflow does not edit files under `frappe_docker/`.

## What It Fixes

In Frappe, `developer_mode=0` alone does not guarantee that browser users cannot
see tracebacks. The **System Settings** value `allow_error_traceback` must also
be disabled. The script applies and verifies both controls.

This hides stack traces, internal paths, and SDK details from browser error
pages. It does not repair the underlying application error. For example, an S3
`NoSuchKey` still means the referenced object is absent and must be restored or
the stale File record must be handled separately.

## Before Running

Update `.env` with production values:

```env
DEPLOYMENT_MODE=production
REQUIRE_PRODUCTION_READY=1
PUBLIC_URL=https://app.example.com
BIND_ADDRESS=127.0.0.1
```

Replace every default password and remove credentials embedded in Git URLs in
`apps.json`. Use a deploy key or Git credential helper instead. Confirm HTTPS
and the reverse proxy are already working.

Optional Frappe request rate limiting can be applied by setting both values:

```env
FRAPPE_RATE_LIMIT=1000
FRAPPE_RATE_LIMIT_WINDOW=3600
```

Leave both empty to retain Frappe's default behavior.

## Commands

Read-only readiness check:

```bash
./production.sh check
```

The check validates production environment guards, known default passwords,
Git URL credentials, backup configuration, required containers, site/database
access, S3 reachability when enabled, and current Frappe production settings.

Apply during an approved maintenance window:

```bash
./production.sh apply
```

Type `PRODUCTION` when prompted. The apply flow:

1. Runs the production preflight.
2. Enables maintenance mode.
3. Runs `backup.sh --yes` and stops if the backup fails.
4. Disables `developer_mode`, tests, and browser error tracebacks.
5. Sets Frappe `host_name` from `PUBLIC_URL`.
6. Enables the scheduler and applies optional rate limits.
7. Runs migrate and clears caches.
8. Restarts Frappe services and verifies the settings.
9. Disables maintenance mode only after verification succeeds.

For trusted automation, confirmation can be skipped with `--yes`. The same
preflight and backup requirements still apply.

Read-only post-deployment verification:

```bash
./production.sh verify
```

## Failure Behavior

If apply fails after maintenance mode is enabled, the script deliberately
leaves the site in maintenance mode. Review the timestamped log under
`logs/scripts/production/` and the container logs. After correcting and
verifying the failure, maintenance mode can be disabled explicitly:

```bash
docker exec docker-setup-backend-1 \
  bench --site frontend set-maintenance-mode off
```

Use the actual `BACKEND_CONTAINER` and `SITE_DOMAIN` values from `.env`.

## Full Launch Review

The script cannot approve DNS, TLS, user permissions, restore testing, or an
operational rollback decision. Complete
[`production-launch-checklist.md`](production-launch-checklist.md) before the
public launch.
