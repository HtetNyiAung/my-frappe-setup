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
| **Payments** | version-16 | [frappe/payments](https://github.com/frappe/payments) | Payments integration |
| **LMS** | main | [frappe/lms](https://github.com/frappe/lms) | Learning Management System |
| **CRM** | main | [frappe/crm](https://github.com/frappe/crm) | Customer Relationship Management |
| **Lending** | develop | [frappe/lending](https://github.com/frappe/lending) | Lending Management |
| **Telephony** | develop | [frappe/telephony](https://github.com/frappe/telephony) | Call/SMS (Helpdesk dependency) |
| **Helpdesk** | develop | [frappe/helpdesk](https://github.com/frappe/helpdesk) | Customer support |
| **Mdea Custom** | main | [HtetNyiAung/mdea_custom](https://github.com/HtetNyiAung/mdea_custom) | Custom app (Member & Subscription) |

---

## 🌐 Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **Frappe / ERPNext** | `http://localhost:8787` | `Administrator` / `admin` |
| **Keycloak Admin** | `http://localhost:8686/auth` | `admin` / `admin` |

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
   chmod +x setup.sh
   ```

2. **Configure Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your passwords and settings if needed
   ```

3. **Run Initialization**:
   This script will automatically clone apps in `apps.json`, build images, and provision the site.
   ```bash
   ./setup.sh
   ```

4. **Start Keycloak** (optional):
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
│   ├── pwd-with-apps.yml              # Main Docker Compose
│   ├── docker-compose.override.yml    # Auto-generated volume mounts for custom apps
│   ├── docker-compose.keycloak.yml    # Keycloak SSO Stack
│   ├── backup.sh                      # Database backup script
│   ├── restore.sh                     # Database restore script
│   ├── update.sh                      # App update script
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
# Run migration (after code changes or adding new DocTypes)
docker compose exec backend bench --site frontend migrate

# Clear cache (fix UI issues after changes)
docker compose exec backend bench --site frontend clear-cache

# Clear website cache
docker compose exec backend bench --site frontend clear-website-cache
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

2. **Re-run setup** to rebuild the Docker image:
   ```bash
   ./setup.sh
   ```

3. **⚠️ Important:** If the app has dependencies (like Helpdesk needs Telephony), check the app's `hooks.py` for `required_apps` and add those to `apps.json` **before** the app.

---

## 🛠️ Key Features

- **Automated Deployment**: `./setup.sh` ensures all apps in `apps.json` are present on the host and installed on the site.
- **Hot Reload Development**: Changes in the `apps/` folder are reflected in real-time inside Docker (volume mounted).
- **SSO Ready**: Built-in Keycloak integration support.
- **Custom App Support**: Apps marked `is_custom: true` in `apps.json` are auto-cloned and volume-mounted for development.

---

## 📚 Documentation Links

- **[Setup Guide](docker-setup/docs/setup.md)**
- **[Keycloak SSO Integration Guide](docker-setup/docs/keycloak-frappe-setup-guide.md)**
- **[Custom App Development Guide](docker-setup/docs/custom-app-setup-guide.md)**
- **[Backup Guide](docker-setup/docs/backup.md)**
- **[Restore Guide](docker-setup/docs/restore.md)**
- **[Update Guide](docker-setup/docs/update.md)**
- **[Logs Guide](docker-setup/docs/logs.md)**
- **[Cleanup Guide](docker-setup/docs/cleanup.md)**