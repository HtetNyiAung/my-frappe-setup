# My Frappe Setup Stack

A complete Docker-based development and deployment stack for **Frappe v16** with **ERPNext**, **HRMS**, **Insights**, **Helpdesk**, and **Custom App Support**, supercharged with **Keycloak SSO**.

---

## 📦 Installed Apps

| App | Branch | Source | Description |
|-----|--------|--------|-------------|
| **Frappe** | version-16 | Core Framework | Base framework |
| **ERPNext** | version-16 | [frappe/erpnext](https://github.com/frappe/erpnext) | ERP system |
| **HRMS** | version-16 | [frappe/hrms](https://github.com/frappe/hrms) | HR Management |
| **Insights** | main | [frappe/insights](https://github.com/frappe/insights) | Data analytics |
| **Insights** | main | [frappe/insights](https://github.com/frappe/insights) | Data analytics |
| **CRM** | main | [frappe/crm](https://github.com/frappe/crm) | CRM system |
| **Lending** | version-16-beta | [frappe/lending](https://github.com/frappe/lending) | Lending system |
| **Mdea Custom** | main | [HtetNyiAung/mdea_custom](https://github.com/HtetNyiAung/mdea_custom) | Custom app |
| **changAI** | main | [ERPGulf/changAI](https://github.com/ERPGulf/changAI) | AI Chat Module |

---

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frappe / ERPNext** | `http://localhost:8787` | `Administrator` / `admin` |
| **Keycloak Admin** | `http://localhost:8686/auth` | `admin` / `admin` |
| **Authentik Admin** | `http://localhost:9000/if/admin/` | `akadmin` / `YourAuthentikPassword` |

---

## 🚀 Step 1: Environment Preparation

### Option A: Windows (Docker Desktop)
1. Download and install **Docker Desktop** from [docker.com](https://www.docker.com/products/docker-desktop)
2. Enable **WSL2** and turn on integration for your Ubuntu/WSL distro.
3. Start Docker Desktop.

### Option B: Ubuntu Server
Run these commands to set up the necessary environment:
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies (Including JQ for automation)
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git jq

# Install Node.js 22 LTS
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

# Install global dependencies required by apps like 'drive'
sudo npm install -g yarn pnpm

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Configure Docker (Add current user to docker group)
sudo usermod -aG docker $USER
# IMPORTANT: Logout and log back in for changes to take effect!
```

---

## 🚀 Step 2: Initialize the Stack

Everything is automated via the `setup.sh` script.

1. **Clone/Enter the Directory**:
   ```bash
   cd docker-setup
   chmod +x setup.sh deploy.sh ops.sh backup.sh restore.sh
   ```

2. **Configure Environment**:
   ```bash
   cp .env.example .env
   cp apps.json.example apps.json
   # Edit .env and apps.json with your settings if needed
   ```

3. **Run Initialization**:
   This script will automatically clone apps in `apps.json`, build images, and provision the site.
   > 🚀 **New Feature:** The script now installs apps one-by-one and continues even if one fails, providing a summary report at the end.
   ```bash
   ./setup.sh
   ```

4. **Install boto3 fallback** (only if an older MinIO image does not include it):
   ```bash
   docker compose -f pwd-with-apps.yml exec backend /home/frappe/frappe-bench/env/bin/pip install boto3
   docker compose -f pwd-with-apps.yml restart backend
   ```
   > Current `setup.sh` and `deploy.sh` add this dependency to S3-enabled images automatically. Use these commands only to repair an older image. See [MinIO S3 Integration Guide](docker-setup/docs/storage/minio-s3-integration-guide.md) for details.

5. **Start Keycloak** (optional):
   ```bash
   docker compose -f docker-compose.keycloak.yml up -d
   ```

---

## 📁 Project Structure

```text
my-frappe-setup/
├── apps/                              # [HOT] Host-side custom apps (Volume Mounted)
│   └── mdea_custom/                   # MDEA Custom Frappe App (Auto-cloned)
├── docker-setup/
│   ├── .env                           # Environment variables (ports, passwords)
│   ├── apps.json                      # Define apps to install
│   ├── setup.sh                       # Fully automated setup & app cloning script
│   ├── deploy.sh                      # Guarded routine application deployment
│   ├── ops.sh                         # Status, logs, restart, cache, and migrate
│   ├── pwd-with-apps.yml              # Main Docker Compose
│   ├── docker-compose.override.yml    # Auto-generated volume mounts for custom apps
│   ├── docker-compose.keycloak.yml    # Keycloak SSO Stack
│   ├── backup.sh                      # Database backup script
│   ├── restore.sh                     # Database restore script
│   ├── update.sh                      # Legacy wrapper for deploy.sh apply
│   ├── cleanup.sh                     # Cleanup script
│   ├── logs.sh                        # Log viewer script
│   └── docs/                          # Detailed Documentation
└── README.md                          # This file
```

---

## 🛠️ Commonly Used Commands

> **Note:** All commands should be run from the `docker-setup/` directory.
> ```bash
> cd ~/test-login/my-frappe-setup/docker-setup
> ```

### 🟢 Start / Stop / Restart

```bash
# Start all Frappe containers
docker compose stop
docker compose start

# Restart all Frappe containers
docker compose restart

# Restart specific services (e.g. after installing a new app)
docker compose restart backend frontend websocket

# Start Keycloak (separate stack)
docker compose -f docker-compose.keycloak.yml up -d

# Stop Keycloak
docker compose -f docker-compose.keycloak.yml stop
```

### 📋 Check Status

```bash
# See running containers
docker compose ps

# List installed apps on site
docker compose exec backend bench --site frontend list-apps

# List all sites
docker compose exec backend bench list-sites
```

### 🔄 Migration & Cache

```bash
# Controlled migration with backup and verification
./ops.sh migrate

# Clear site and website cache
./ops.sh clear-cache
```

### 📦 Install / Remove Apps

```bash
# Install a new app (must exist in /apps/ inside container)
docker compose exec backend bench --site frontend install-app <app_name>

# Download + install an app directly
docker compose exec backend bench get-app <github_url> --branch <branch>
docker compose exec backend bench --site frontend install-app <app_name>

# ⚠️ After installing a new app, always restart:
docker compose restart backend frontend websocket queue-short queue-long scheduler
```

### 🪵 View Logs

```bash
# View backend logs (most useful for debugging)
docker compose logs backend --tail 50

# Follow logs in real-time
docker compose logs backend -f

# View all container logs
docker compose logs --tail 30

# View Keycloak logs
docker compose -f docker-compose.keycloak.yml logs keycloak --tail 30
```

### 💾 Backup & Restore

```bash
# Backup
./backup.sh

# Restore
./restore.sh
```

#### Automated daily backup with cron

Run and verify one non-interactive backup before adding the schedule. Replace
`/absolute/path/to/my-frappe-setup` with the actual absolute project path on
the server.

```bash
cd /absolute/path/to/my-frappe-setup/docker-setup
chmod +x backup.sh
./backup.sh --yes
```

Set the local and container retention values in `docker-setup/.env` as needed:

```env
BACKUP_RETENTION_DAYS=14
CONTAINER_BACKUP_KEEP_COUNT=3
```

Check the server timezone before choosing the cron schedule:

```bash
timedatectl
date
```

Edit the current user's crontab:

```bash
crontab -e
```

The following example runs daily at `19:30` in the server timezone. On a UTC
server, that is `02:00` Myanmar time on the following day. If the server itself
uses Myanmar time, use `0 2 * * *` instead.

```cron
30 19 * * * /absolute/path/to/my-frappe-setup/docker-setup/backup.sh --yes >> /absolute/path/to/my-frappe-setup/docker-setup/backups/cron-backup.log 2>&1
```

Use an absolute path because cron does not start in the project directory. The
cron user must be able to run Docker and access `docker-setup/.env` and the
backup directory. The `--yes` flag is required because cron cannot answer the
script's interactive confirmation.

Verify the installed entry and review the backup log:

```bash
crontab -l
tail -f /absolute/path/to/my-frappe-setup/docker-setup/backups/cron-backup.log
```

Confirm that the new timestamped backup directory contains non-empty database,
public-files, private-files, and site-configuration backup files. For timezone,
retention, offsite backup, restore testing, and troubleshooting details, see the
[Backup Automation Guide](docker-setup/docs/operations/backup-automation-guide.md).

### 🔧 Bench Console & Shell

```bash
# Open Frappe console (Python REPL with Frappe context)
docker compose exec backend bench --site frontend console

# Open MariaDB shell
docker compose exec backend bench --site frontend mariadb

# Open bash shell inside backend container
docker compose exec backend bash
```

### 🧹 Cleanup

```bash
# Full cleanup (removes containers, volumes, images)
./cleanup.sh
```

---

## ➕ Adding a New App

1. **Edit `apps.json`** — add the app entry:
   ```json
   {
     "url": "https://github.com/org/app-name",
     "branch": "version-16",
     "is_custom": false
   }
   ```
   > 💡 For custom apps, add `"name": "app_name"` and `"is_custom": true`

2. **Plan and apply a deployment**:
   ```bash
   ./deploy.sh check
   ./deploy.sh plan
   ./deploy.sh apply
   ```

3. **⚠️ Important:** If the app has dependencies (like Helpdesk needs Telephony), check the app's `hooks.py` for `required_apps` and add those to `apps.json` **before** the app.

---

## 🛠️ Key Features

- **First Setup**: `./setup.sh` creates and configures a new stack/site.
- **Guarded Deployment**: `./deploy.sh` backs up, migrates, and verifies an existing site.
- **Focused Operations**: `./ops.sh` handles status, logs, restarts, cache, and controlled migration.
- **Hot Reload Development**: Changes in the `apps/` folder are reflected in real-time inside Docker (volume mounted).
- **SSO Ready**: Built-in Keycloak integration support.
- **Custom App Support**: Apps marked `is_custom: true` in `apps.json` are auto-cloned and volume-mounted for development.

---

## 📚 Documentation Links

- **[Documentation Index](docker-setup/docs/README.md)**
- **[Myanmar Script Usage Guide](docker-setup/docs/guide/script-usage-guide-my.md)**
- **[Setup Guide](docker-setup/docs/setup/setup.md)**
- **[Application Deployment Guide](docker-setup/docs/deployment/deploy.md)**
- **[Runtime Operations Guide](docker-setup/docs/operations/operations.md)**
- **[Three-Server Deployment Architecture and Scaling Guide](docker-setup/docs/deployment/deployment-architecture.md)**
- **[External MariaDB on Ubuntu VM](docker-setup/docs/database/external-database-ubuntu.md)**
