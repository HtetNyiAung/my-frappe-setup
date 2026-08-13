# Application Deployment Guide

Use `deploy.sh` for normal code releases after the site has been created by
`setup.sh`. Run all commands from `docker-setup/`.

## Command Summary

| Command | Changes state? | Purpose |
|---|---:|---|
| `./deploy.sh check` | No | Validate `.env`, `apps.json`, Git access, Compose, services, site, and database access. |
| `./deploy.sh plan` | No | Display observed remote branch/tag revisions and the deployment sequence. |
| `./deploy.sh apply` | Yes | Build, back up, deploy, migrate, clear caches, restart, and verify. |
| `./deploy.sh verify` | No | Verify services, site availability, and database access. |

Recommended release sequence:

```bash
./deploy.sh check
./deploy.sh plan
./deploy.sh apply
./deploy.sh verify
```

`apply` requires typing `DEPLOY`. Trusted CI or automation may use:

```bash
./deploy.sh apply --yes
```

## What `apply` Does

1. Validates Docker, Compose, the existing site, database access, and every
   configured Git branch or tag.
2. Resolves and records the observed remote commit for each `apps.json` entry.
3. Builds a candidate image while the current containers remain running.
4. Enables Frappe Maintenance Mode and stops scheduler/queue workers.
5. Runs `backup.sh --yes`. Deployment stops if the verified backup fails.
6. Synchronizes host-mounted custom apps to their configured branches.
7. Keeps the previous image under a timestamped `-rollback-...` tag and makes
   the candidate the configured `CUSTOM_IMAGE`.
8. Recreates application services, installs any newly configured app, and runs
   `bench migrate` exactly once as a required step.
9. Clears site and website caches and recreates the remaining Frappe services.
10. Verifies the services and database connection before disabling Maintenance
    Mode.
11. Writes a source revision record under `logs/releases/`.

## Failure Behaviour

- A Git access or image-build failure happens before Maintenance Mode and does
  not recreate the running containers.
- A backup failure stops deployment before the new image is activated.
- A sync, service, migration, or verification failure leaves Maintenance Mode
  enabled. Background writers may also remain stopped.
- The script does not automatically restore a database after migration starts.
  Schema rollback must be a deliberate recovery decision based on the matching
  code image and verified backup.

Inspect a failed release with:

```bash
./ops.sh status
./ops.sh logs backend
./ops.sh logs scheduler
```

After correcting and verifying the problem, explicitly disable Maintenance
Mode:

```bash
./ops.sh maintenance-off
```

If the previous image is required, first identify the timestamped rollback tag,
retag it as `CUSTOM_IMAGE`, recreate the Frappe services, and run verification.
Do this only with code/database compatibility confirmed; host-mounted custom
apps must also be returned to their recorded revisions:

```bash
docker image ls
docker tag <rollback-image-tag> <CUSTOM_IMAGE>
docker compose -f <COMPOSE_FILE> -f docker-compose.override.yml up -d \
  --no-deps --force-recreate \
  backend websocket frontend queue-long queue-short scheduler
./ops.sh status
```

## Private GitHub Apps

Use clean repository URLs in `apps.json`, set `"private": true`, and store the
fine-grained read-only token only in the ignored `.env` file as
`GITHUB_TOKEN`. The deployment script disables interactive Git credential
prompts, validates access before the build, redacts the token from build output,
and deletes its temporary authenticated file.

## Important Boundaries

- `deploy.sh` deploys code to an existing site. It does not create a site.
- `setup.sh` is for first installation or explicit infrastructure
  reconfiguration.
- `production.sh` applies production security/runtime settings; it is not the
  normal application release command.
- `backup.sh` and `restore.sh` remain separate data-management tools.
