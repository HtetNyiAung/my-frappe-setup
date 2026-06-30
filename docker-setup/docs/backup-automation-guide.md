# Backup Automation Guide

Complete guide for protecting your Frappe site with **local backups**, **scheduled runs**, **retention**, and **offsite Google Drive** copies.

Use this together with:

- [`backup.sh`](../backup.sh) — local backup script
- [`restore.sh`](../restore.sh) — restore from a backup folder
- [`backup.md`](backup.md) — short reference for `backup.sh`

---

## Overview

| Layer | What | Where | Purpose |
|-------|------|-------|---------|
| **1. Live data** | Docker volumes | Server | Day-to-day operation |
| **2. Local backup** | `backup.sh` | `./backups/` on host | Fast restore on same server |
| **3. Offsite backup** | Frappe Google Drive | Google Cloud | Survives server loss |

Follow the **3-2-1 rule**:

- **3** copies of your data
- **2** different storage types (disk + cloud)
- **1** copy offsite (Google Drive)

For ~3000 registered users with ~300 peak concurrent users, a single server with local + offsite backup is sufficient. Scaling is a separate topic; backup protects you regardless of user count.

---

## Layer 1 — Local backup (`backup.sh`)

### What it does

1. Runs `bench --site <site> backup --with-files` inside the backend container.
2. Copies SQL + file archives to `./backups/YYYY-MM-DD_HH-MM-SS/` on the host.
3. Deletes backup folders older than `BACKUP_RETENTION_DAYS` (default **7**).

### Configuration

In `.env`:

```env
BACKUP_RETENTION_DAYS=7
```

### Manual run

```bash
cd docker-setup
chmod +x backup.sh
./backup.sh
```

Output:

```
./docker-setup/backups/2026-06-29_02-00-00/
```

### Retention behaviour

- Only runs **after** a successful backup.
- Removes **entire timestamp folders** under `./backups/` older than the retention window.
- Folders with spaces in the name are handled safely.
- Set `BACKUP_RETENTION_DAYS=14` (or any positive integer) in `.env` to change the window without editing the script.

### Restore

See [`restore.md`](restore.md).

```bash
./restore.sh ./backups/2026-06-29_02-00-00
```

---

## Layer 2 — Cron schedule (daily auto-run)

Cron is the Linux scheduler. It runs `backup.sh` automatically at a fixed time so you do not rely on someone remembering to run it.

### Timezone warning

Check your server timezone first:

```bash
timedatectl
# or
date
```

If the server uses **UTC** (common on cloud VPS) and you want **Myanmar time 02:00** (UTC+6:30), schedule at **19:30 UTC** the previous calendar day — not `0 2 * * *`.

| Desired run time | Server timezone | Cron expression |
|------------------|-----------------|-----------------|
| Myanmar 02:00 daily | UTC | `30 19 * * *` |
| Server local 02:00 | Matches your zone | `0 2 * * *` |

### Cron line format

```
┌─ minute (0-59)
│ ┌ hour (0-23)
│ │ ┌ day of month
│ │ │ ┌ month
│ │ │ │ ┌ day of week
│ │ │ │ │
0 2 * * *   command
```

### Setup steps

1. Use the **full path** to `backup.sh` (cron does not use your shell working directory).

2. Log output to a file so failures are visible:

```bash
crontab -e
```

Add one line (adjust path and time as needed):

```cron
30 19 * * * /home/hnna/my-frappe-setup/docker-setup/backup.sh >> /home/hnna/my-frappe-setup/docker-setup/backups/cron-backup.log 2>&1
```

3. Verify:

```bash
crontab -l
```

4. Ensure the cron user can run Docker (`docker exec` in `backup.sh`). On production, add the user to the `docker` group or run cron as root.

### WSL2 note

On **WSL2**, the cron daemon may not start automatically after reboot:

```bash
sudo service cron start
sudo service cron status
```

On a real Linux production server, cron usually starts on boot.

### What runs each night

```
Cron triggers backup.sh
        │
        ▼
  New folder in ./backups/
        │
        ▼
  Retention deletes folders older than 7 days
        │
        ▼
  Result appended to cron-backup.log
```

---

## Layer 3 — Offsite backup (Frappe Google Drive)

Frappe has **built-in Google Drive backup**. No `rclone`, `aws-cli`, or custom upload script is required for this option.

Recommended for this stack because:

- Setup is done in the Admin Console UI.
- Frappe scheduler handles daily uploads.
- Works alongside `backup.sh` (local fast restore + cloud disaster recovery).

### Prerequisites

| Requirement | Notes |
|-------------|-------|
| **System User** | Administrator with Admin Console (`/app`) access |
| **Scheduler running** | `scheduler` service in `pwd-with-apps.yml` must be up |
| **Public HTTPS URL** | e.g. `https://lms.inyaland.com` from `PUBLIC_URL` in `.env` |
| **Google account** | Account that will own the backup folder on Drive |

> Prefer setting up Google Drive on your **production domain**, not `localhost:8787`. Google OAuth redirect URIs are easier with a stable HTTPS URL.

### Part A — Google Cloud Console (one-time)

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Create a project (e.g. `inyaland-backup`).
3. **APIs & Services → Library** → enable **Google Drive API**.
4. **APIs & Services → Credentials** → configure **OAuth consent screen** (External or Internal).
5. **Create Credentials → OAuth client ID**:
   - Application type: **Web application**
   - Name: e.g. `Frappe Backup`
6. Add authorized URLs (replace with your real domain):

**Authorized JavaScript origins:**

```
https://lms.inyaland.com
```

**Authorized redirect URIs:**

```
https://lms.inyaland.com/api/method/frappe.integrations.google_oauth.callback
```

7. Copy **Client ID** and **Client Secret**.

### Part B — Frappe Admin Console

1. Log in to Admin Console: `https://lms.inyaland.com/app`
2. Open **Google Settings** (search in Awesome Bar or **Integrations → Google Services → Google Settings**).
3. Paste **Client ID** and **Client Secret** → **Save**.
4. Open **Google Drive** (**Integrations → Google Services → Google Drive**).
5. Click **New** and fill in:

| Field | Example |
|-------|---------|
| Backup Folder Name | `inyaland-backup` |
| Frequency | **Daily** |
| Send Notification To | `admin@example.com` |

6. **Save** → click **Authorize Drive Access** → sign in with Google → **Allow**.
7. Click **Take Backup** to test.
8. Confirm files appear in Google Drive under your folder name.

### How automatic offsite backup works

| Trigger | Behaviour |
|---------|-----------|
| **Take Backup** button | Immediate backup + upload |
| **Frequency = Daily** | Frappe scheduler uploads on schedule |
| On completion | Email sent to **Send Notification To** |

Ensure scheduler is running:

```bash
docker ps | grep scheduler
```

### Google Drive storage limits

- Free Google accounts: **15 GB** total Drive quota.
- LMS course media can grow quickly; monitor usage.
- If backups exceed **1 GB** compressed, Frappe may upload the latest existing backup instead of generating a new one (see Frappe docs).

### Troubleshooting

#### `redirect_uri_mismatch`

- Redirect URI in Google Console must **exactly** match your public site URL.
- Use `https://`, not `http://`.
- Do not add wrong ports (e.g. `:8000`) unless your site is actually served on that port.
- Confirm **System Settings → Site URL** and site `host_name` match `PUBLIC_URL`.

#### Auto backup not running

- [ ] `scheduler` container is running
- [ ] Google Drive record shows **Authorized**
- [ ] **Frequency** is set (e.g. Daily)
- [ ] Check scheduler / error logs: `./logs.sh`

#### Backup works manually but not on schedule

- Scheduler may be disabled inside the site. In the backend container:

```bash
docker exec -it docker-setup-backend-1 bench --site frontend doctor
```

Review scheduler status in Frappe documentation for your version.

---

## Recommended production setup

Combine all three layers:

```
┌─────────────────────────────────────────────────────────┐
│  Nightly (cron)                                         │
│  backup.sh → ./backups/ → retention (7 days)            │
└─────────────────────────────────────────────────────────┘
                          +
┌─────────────────────────────────────────────────────────┐
│  Daily (Frappe scheduler)                               │
│  Google Drive → offsite copy on Google Cloud            │
└─────────────────────────────────────────────────────────┘
```

| Scenario | Use |
|----------|-----|
| Quick restore on same server | Local `./backups/` + `restore.sh` |
| Server disk failure / ransomware | Google Drive copy |
| Long-term archive beyond 7 days | Google Drive (or extend retention + offsite) |

---

## Checklist

### Local backup

- [ ] `backup.sh` is executable
- [ ] `BACKUP_RETENTION_DAYS` set in `.env`
- [ ] Manual `./backup.sh` run succeeded
- [ ] Backup folder exists under `./backups/`

### Cron

- [ ] Server timezone confirmed
- [ ] Cron line uses full path to `backup.sh`
- [ ] Log file path configured (`cron-backup.log`)
- [ ] `crontab -l` shows the entry
- [ ] Cron user can run `docker` commands
- [ ] (WSL only) `cron` service is started

### Offsite (Google Drive)

- [ ] Google Drive API enabled
- [ ] OAuth redirect URI matches production domain
- [ ] Google Settings saved in Frappe
- [ ] Google Drive record authorized
- [ ] **Take Backup** test succeeded
- [ ] Files visible in Google Drive
- [ ] Notification email received
- [ ] `scheduler` container running

### Security

- [ ] Default passwords changed in `.env`
- [ ] `PUBLIC_URL` uses HTTPS
- [ ] Google Client Secret not committed to git
- [ ] Restore tested at least once on a non-production copy (monthly recommended)

---

## Related docs

- [`backup.md`](backup.md) — `backup.sh` quick reference
- [`restore.md`](restore.md) — restore procedure
- [`checklists.md`](checklists.md) — production hosting checklist
