# Runtime Operations Guide

Use `ops.sh` for day-to-day operations on an existing stack. It reads `.env`
and automatically includes `docker-compose.override.yml` when present.

## Status and Logs

```bash
./ops.sh status
./ops.sh logs
./ops.sh logs backend
./ops.sh logs backend --tail 200
./ops.sh logs backend --follow
```

`status` checks the six long-running Frappe services, confirms that the site
exists, and tests its database connection.

## Restart and Cache

```bash
./ops.sh restart
./ops.sh clear-cache
```

`restart` requires typing `RESTART`. `clear-cache` runs both Frappe site-cache
and website-cache clearing without rebuilding an image or migrating the
database.

## Controlled Migration

Use this only when code is already deployed and a separate migration is
required:

```bash
./ops.sh migrate
```

It acquires the same deployment lock used by `deploy.sh`, enables Maintenance
Mode, stops scheduler/queue workers, creates a verified backup, runs migration,
clears caches, restarts, verifies, and then disables Maintenance Mode.

If migration fails, the script leaves Maintenance Mode enabled and the writers
stopped. Inspect and repair the problem before continuing. Do not automatically
restore the database unless the rollback code version and backup have been
selected and verified.

## Maintenance Mode Recovery

```bash
./ops.sh maintenance-on
./ops.sh maintenance-off
```

Enabling requires typing `MAINTENANCE`. Disabling requires typing `RECOVERED`
so a failed deployment is not accidentally exposed to users. Trusted
automation can pass `--yes` to mutating commands.

## Which Script Should I Use?

| Need | Command |
|---|---|
| First site installation | `./setup.sh` |
| Infrastructure or generated Compose reconfiguration | `./setup.sh --reconfigure` |
| Routine code/app update | `./deploy.sh apply` |
| Database migration without a code build | `./ops.sh migrate` |
| Cache clearing | `./ops.sh clear-cache` |
| Service restart | `./ops.sh restart` |
| Runtime diagnosis | `./ops.sh status`, `./ops.sh logs` |
| Production hardening | `./production.sh check/apply/verify` |
| Backup or restore | `./backup.sh`, `./restore.sh` |
