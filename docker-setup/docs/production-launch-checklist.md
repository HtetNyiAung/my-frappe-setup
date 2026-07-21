# Production Launch Checklist

Project: Frappe Application Deployment  
Stack: Frappe Docker setup  
Audience: system administrator, deployment engineer, application administrator

Use this checklist before launching a Frappe site for real users. This guide is intentionally generic so it can be reused for different Frappe apps.

## 1. Launch Decision

- [ ] Confirm this is the approved production server.
- [ ] Confirm the launch date and support window.
- [ ] Confirm who can approve emergency rollback.
- [ ] Confirm staging/testing and production data are separated.
- [ ] Confirm no test-only data appears to production users.
- [ ] Confirm the application owner has accepted the launch scope.

Recommended rollout:

```text
Internal test -> limited user rollout -> full production rollout
```

Avoid launching to all users before login, access control, backup, restore, and notifications are tested.

## 2. Domain and HTTPS

- [ ] DNS record is created.
- [ ] Domain points to the production server.
- [ ] HTTPS certificate is installed.
- [ ] Reverse proxy is configured.
- [ ] HTTP redirects to HTTPS.
- [ ] Frappe `host_name` is set to the public URL.

Recommended `.env` values:

```env
SITE_DOMAIN=frontend
PUBLIC_URL=https://app.example.com
FRAPPE_PORT=8787
FRAPPE_INTERNAL_PORT=8080
BIND_ADDRESS=127.0.0.1
```

Recommended traffic flow:

```text
User Browser
  -> https://app.example.com
  -> HTTPS reverse proxy
  -> http://127.0.0.1:8787
  -> Docker frontend container:8080
```

Do not expose `FRAPPE_INTERNAL_PORT=8080` directly to users.

## 3. Docker Compose Review

- [ ] `CUSTOM_IMAGE` is correct.
- [ ] `FRAPPE_SITE_NAME_HEADER` uses the internal site name.
- [ ] Named volumes are used for database and site files.
- [ ] `restart: unless-stopped` exists for long-running services.
- [ ] Healthchecks exist for database, Redis, backend, frontend, and websocket.
- [ ] Log rotation is configured.
- [ ] Memory limits are suitable for server size.
- [ ] Frontend service exposes only the intended host port.
- [ ] Database service is not exposed publicly.

Recommended DB port for production with local-only database client access:

```yaml
ports:
  - "127.0.0.1:3307:3306"
```

Use this only for trusted internal LAN testing:

```yaml
ports:
  - "3307:3306"
```

If direct database client access is not needed, remove the DB `ports` section.

## 4. Secrets and Passwords

- [ ] `.env` is not committed to Git.
- [ ] `ADMIN_PASSWORD` is not `admin`.
- [ ] `MYSQL_ROOT_PASSWORD` is strong.
- [ ] `MARIADB_ROOT_PASSWORD` is strong.
- [ ] `DB_PASSWORD` is strong.
- [ ] Optional service default passwords are changed if enabled.
- [ ] Secret keys are generated with strong random values.
- [ ] Git access tokens are not stored in committed URLs.

Do not use production passwords from `.env.example`.

Recommended secret generation:

```bash
openssl rand -base64 32
```

## 5. Git and App Sources

- [ ] `apps.json` contains only approved apps.
- [ ] `apps.json` does not contain exposed access tokens.
- [ ] App branches/tags are approved.
- [ ] Custom app source is version controlled.
- [ ] Production deploy uses tested commits, tags, or release branches.
- [ ] Private apps use deploy keys or another secure access method.

Recommended pattern:

```text
frappe app     -> matching Frappe version branch/tag
dependency app -> matching compatible branch/tag
custom app     -> project-controlled branch/tag
```

Avoid using moving branches for production unless they were tested in staging first.

## 6. Backup Before Launch

- [ ] Run a manual backup before launch.
- [ ] Confirm backup file exists.
- [ ] Confirm backup includes database.
- [ ] Confirm backup includes private files.
- [ ] Confirm backup includes public files.
- [ ] Copy backup outside the server.
- [ ] Test restore on a non-production machine.

Recommended command:

```bash
cd /path/to/docker-setup
./backup.sh
```

Production recommendation:

```env
AUTO_BACKUP_BEFORE_SETUP=1
REQUIRE_BACKUP_BEFORE_SETUP=1
```

## 7. Restore Test

- [ ] Restore process is documented.
- [ ] Restore was tested with a real backup.
- [ ] Admin login works after restore.
- [ ] Uploaded files open after restore.
- [ ] Core application pages open after restore.
- [ ] Background jobs still run after restore.

Do not consider backup complete until restore was tested at least once.

## 8. Database Access

- [ ] Database client access is limited.
- [ ] DB port is not exposed publicly.
- [ ] Root password is strong.
- [ ] Site database credentials are stored securely.
- [ ] Firewall allows DB access only from trusted machines.
- [ ] Remote DB access uses SSH tunnel or VPN when possible.

Recommended for production:

```yaml
ports:
  - "127.0.0.1:3307:3306"
```

For remote admin access, prefer SSH tunnel instead of exposing MariaDB to the network.

See also:

```text
docs/database-client-access.md
```

## 9. User and Role Readiness

- [ ] Administrator account works.
- [ ] Emergency admin account exists.
- [ ] Application administrator role is tested.
- [ ] Normal user account is tested.
- [ ] Restricted user account is tested.
- [ ] Disabled user cannot login.
- [ ] Users do not see admin-only modules.
- [ ] Normal users can access the intended application pages.
- [ ] Normal users cannot access restricted Desk areas.

Avoid giving normal users:

```text
Administrator
System Manager
Website Manager
Developer
```

unless explicitly required.

## 10. Login and Authentication

- [ ] Password login works.
- [ ] Email link login policy is decided.
- [ ] Two Factor Authentication policy is decided.
- [ ] SSO plan is documented if used.
- [ ] Backup admin can still login without SSO dependency.
- [ ] Disabled users cannot login.
- [ ] Password reset/email flow is tested.

Recommended:

```text
Pilot: local login first
Production: SSO only after testing with a small group
Always keep one emergency admin account
```

## 11. Email and Notifications

- [ ] Outgoing email account is configured.
- [ ] Test email sends successfully.
- [ ] Password reset email is received.
- [ ] Important workflow notifications are tested.
- [ ] Email sender name is correct.
- [ ] SPF/DKIM/DMARC are planned for the sending domain.

Do not launch notification-heavy workflows before email is tested.

## 12. Branding and Localization

- [ ] Application name is correct.
- [ ] Logo is correct.
- [ ] Primary color is correct.
- [ ] Public URL is correct.
- [ ] Login page text is reviewed.
- [ ] Required languages display correctly.
- [ ] Browser hard refresh tested after branding changes.
- [ ] Translation CSV changes are in a permanent custom app or documented as test-only.

Recommended:

```text
Keep core app source clean
Put project-specific translations and branding in a custom app
Use Unicode for non-English content
```

## 13. Application Data Readiness

- [ ] Production master data is reviewed.
- [ ] Test records are hidden or removed.
- [ ] Required records are created.
- [ ] Required workflows are tested.
- [ ] File attachments open correctly.
- [ ] Public/private file behavior is tested.
- [ ] Print formats or exported documents are tested if used.
- [ ] User access rules are correct.

Avoid using sample/demo records in production.

## 14. Access Control

- [ ] Private/internal access is confirmed.
- [ ] Public pages are intentional.
- [ ] Restricted records are protected.
- [ ] Users can see only allowed content.
- [ ] Managers have only required permissions.
- [ ] Admin-only menu items are hidden from normal users.
- [ ] Permission changes are tested with real user accounts.

Recommended:

```text
Normal users use application pages
Administrators use /desk
```

## 15. File Uploads and Storage

- [ ] Upload size limit is suitable.
- [ ] Large file upload is tested.
- [ ] File storage strategy is decided.
- [ ] Private file access is tested.
- [ ] Public file access is tested.
- [ ] Disk free space is checked.
- [ ] Backup includes uploaded files.

Current compose value:

```yaml
CLIENT_MAX_BODY_SIZE: 50m
```

Increase only if large uploads are required.

## 16. Performance Checks

- [ ] `docker stats` checked under normal usage.
- [ ] Login page loads quickly.
- [ ] Main application pages load quickly.
- [ ] Large list/report pages are tested.
- [ ] File upload/download is tested.
- [ ] Background workers are running.
- [ ] Scheduler is running.

Useful command:

```bash
docker stats
```

If memory usage is near limits, increase resources before launch.

## 17. Security Review

- [ ] Server firewall is enabled.
- [ ] Only required ports are open.
- [ ] Database is not publicly exposed.
- [ ] Admin passwords are strong.
- [ ] Default accounts are removed or secured.
- [ ] Backups are protected.
- [ ] Git secrets are removed.
- [ ] HTTPS is active.
- [ ] Security headers are reviewed in reverse proxy.
- [ ] Server SSH access is restricted.

Recommended public ports:

```text
80  -> redirect to HTTPS
443 -> HTTPS
22  -> SSH, restricted
```

Avoid exposing:

```text
3306 / 3307
8080
8787
9000
```

unless intentionally restricted.

## 18. Monitoring and Logs

- [ ] Docker logs are rotating.
- [ ] Error logs are checked.
- [ ] Backup logs are checked.
- [ ] Disk usage is monitored.
- [ ] Admin knows how to view logs.
- [ ] Alerting plan exists for disk full or service down.

Useful commands:

```bash
docker compose logs -f frontend
docker compose logs -f backend
docker compose logs -f queue-long
docker compose logs -f scheduler
```

## 19. Upgrade and Rollback

- [ ] Current Git commit is recorded.
- [ ] Current Docker image tag is recorded.
- [ ] Current `apps.json` app versions are recorded.
- [ ] Backup is taken before update.
- [ ] Rollback steps are documented.
- [ ] Update was tested outside production.
- [ ] Database migration was tested before production.

Before changing app versions:

```text
backup -> rebuild/update -> migrate -> smoke test
```

Never run cleanup scripts on production unless data deletion is intentional.

## 20. Go-Live Smoke Test

- [ ] Open the production URL.
- [ ] Login as Administrator.
- [ ] Login as application administrator.
- [ ] Login as normal user.
- [ ] Open main application pages.
- [ ] Create or update a test record if allowed.
- [ ] Open an existing production record.
- [ ] Upload or open a file if the app uses files.
- [ ] Trigger a workflow or background job if used.
- [ ] Logout works.
- [ ] Password reset works.
- [ ] Mobile browser tested if users need mobile access.

## 21. Launch Day Checklist

- [ ] Backup completed.
- [ ] Reverse proxy running.
- [ ] HTTPS certificate valid.
- [ ] Docker containers healthy.
- [ ] Email test passed.
- [ ] Admin support contact ready.
- [ ] User guide shared.
- [ ] Known issues documented.
- [ ] Rollback plan ready.

Container health:

```bash
docker compose ps
```

## 22. Post-Launch Checklist

- [ ] Monitor logs for first 24 hours.
- [ ] Check failed login attempts.
- [ ] Check email delivery.
- [ ] Check user access issues.
- [ ] Collect user feedback.
- [ ] Review memory and disk usage.
- [ ] Confirm daily backup ran.
- [ ] Schedule first production maintenance window.

## Final Approval

Production launch should proceed only when these are confirmed:

- [ ] HTTPS works.
- [ ] Backup and restore are proven.
- [ ] Admin and normal user login are tested.
- [ ] Access permissions are correct.
- [ ] No default passwords are used.
- [ ] No secrets are committed to Git.
- [ ] Rollback plan is ready.

Approved by:

```text
Name:
Role:
Date:
Notes:
```
