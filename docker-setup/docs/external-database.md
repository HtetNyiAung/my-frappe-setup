# External MariaDB

This setup supports either the bundled MariaDB container or a separate MariaDB
server. The default remains local so existing installations continue to work.

For commands to install, secure, firewall, back up, and monitor MariaDB on a
separate Ubuntu VM, follow
[External MariaDB on an Ubuntu VM](external-database-ubuntu.md). That document
is the canonical step-by-step procedure for fresh setup, existing-site
migration, verification, and rollback. This document is a concise connection
mode overview.

## Modes

Use the bundled database:

```env
DATABASE_MODE=local
DB_HOST=db
DB_PORT=3306
```

Use a separate database server:

```env
DATABASE_MODE=external
DB_HOST=private-db.example.internal
DB_PORT=3306
DB_ROOT_USERNAME=frappe_provisioner
DB_ROOT_PASSWORD=replace-with-a-strong-secret
DB_NAME=
DB_PASSWORD=replace-with-a-strong-site-password
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false
```

`DB_HOST` must resolve and be reachable from both the application host and the
Frappe containers. Do not use `localhost` or `127.0.0.1`: inside a container,
those addresses refer to the container itself.

## Database Server Requirements

- Use a MariaDB release compatible with the deployed Frappe version. The
  current Frappe `version-16` requirement is MariaDB 11.8; recheck the official
  Frappe installation requirements before provisioning or upgrading.
- Configure `utf8mb4` and `utf8mb4_unicode_ci`.
- Allow TCP connections only from the application server's private IP or
  private network.
- Do not expose port 3306 to the public internet.
- Use a dedicated provisioning account instead of remote root where possible.
- Give the runtime site user access only to its own database.
- Enable transport encryption when traffic crosses an untrusted network.
- Operate independent database backups and restore tests on the DB server.

The provisioning user needs permission to create the site database and user
during `bench new-site`. It can be removed from the application `.env` after a
fresh site has been created if no automated credential repair is required.

## Fresh Site

1. Provision the external MariaDB server and private firewall rule. For Ubuntu,
   use [the Ubuntu VM guide](external-database-ubuntu.md).
2. Set `DATABASE_MODE=external` and the external database variables in `.env`.
3. Run `./setup.sh` and verify the displayed database target before typing
   `SETUP`.
4. Verify login, record creation, background jobs, backup, and restore.

In external mode, `setup.sh` starts the Frappe and Redis services without
starting the local `db` service. It validates TCP reachability first. Fresh site
creation then validates the administrative credentials.

If a local `db` container was already running before the switch, setup leaves it
untouched for rollback. After external validation, it may be stopped without
deleting its volume:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml stop db
```

## Existing Site Migration

Use a maintenance window. Changing `DB_HOST` does not copy existing data.

1. Keep the current stack in `DATABASE_MODE=local` and run `./backup.sh`.
2. Verify that the backup contains a non-empty database dump and both file
   archives. Keep the local DB volume unchanged for rollback.
3. Enable Frappe maintenance mode and stop the scheduler and queue workers so
   no writes occur during the final dump.
4. Take a final backup and import its `*-database.sql.gz` into the external
   database.
5. Create the external site database user with the same database name and
   password stored in the site's `site_config.json`, granting access only to
   that database.
6. Set `DATABASE_MODE=external`, `DB_HOST`, `DB_PORT`, and external admin
   credentials in `.env`.
7. Run `./setup.sh`. The configurator updates `common_site_config.json`, and
   setup aborts if the existing site cannot authenticate to the target.
8. Run `bench migrate`, clear caches, and verify login, read/write operations,
   workers, scheduler, file access, backup, and a test restore.
9. Disable maintenance mode only after all checks pass.

Do not run `cleanup.sh` while the old local DB volume is being retained for
rollback because cleanup intentionally removes project Docker volumes.

## Rollback

Before accepting new production writes on the external database:

1. Set `DATABASE_MODE=local`, `DB_HOST=db`, and `DB_PORT=3306`.
2. Run `./setup.sh` to reconnect the application to the untouched local DB.
3. Verify the site and then disable maintenance mode.

After external writes begin, switching back to the old local database loses
those newer writes. A later rollback requires a reverse migration or restore.

## Credential Repair

Automatic credential repair is disabled for external databases by default:

```env
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false
```

Enable it only during a controlled repair after confirming the configured
provisioning account and target host. The repair helper never prints passwords
and grants the site user access only to its own database.
