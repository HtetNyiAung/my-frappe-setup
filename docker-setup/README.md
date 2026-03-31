# My Frappe Stack + Keycloak SSO

A complete, production-ready, Docker-based deployment stack configured for **Frappe ERPNext**, **HRMS**, **Insights**, and secured with a dedicated **Keycloak SSO** authenticator.

## Overview

This repository uses Docker Compose to orchestrate:
- **Frappe Framework** (ERPNext, HRMS, Insights - v16)
- **MariaDB** (Database)
- **Redis** (Cache & Queue)
- **Keycloak** (Identity & Access Management SSO - Option 1)
- **Authentik** (Identity Provider SSO - Option 2)
- **PostgreSQL** (SSO-specific Database)

All services communicate securely over internal Docker bridge networks, keeping your databases safely isolated from the public internet.

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- Docker Engine & Docker Compose installed
- At least 4GB of RAM (8GB highly recommended)

### 2. Configure Environment
Before starting, copy the example environment file and define your setup:
```bash
cd docker-setup
cp .env.example .env
```
> **Note:** For production, edit `.env` and change `KC_RUN_MODE=start`, use secure passwords, and set your real domains in `SITE_DOMAIN` and `KC_HOSTNAME`.

### 3. Start the Stack (Installation)
Because we use a custom Docker image that bundles **ERPNext, HRMS, and Insights**, you must build the image and provision the Frappe site using the included setup script before turning on Keycloak.

```bash
# 1. Make scripts executable
chmod +x setup.sh logs.sh cleanup.sh backup.sh restore.sh

# 2. Build the Frappe Image, provision the site, and start the Frappe stack
./setup.sh

### Understanding `setup.sh` Commands

*   **`./setup.sh` (Normal Case):**
    Use this for standard daily operations. It **skips** the time-consuming Docker build if the image already exists. This makes it very fast and resilient to network/VPN issues while starting your containers.

*   **`./setup.sh --rebuild` (Maintenance Case):**
    Use this when you **need to update your apps** (like ERPNext, HRMS, or Insights) to their latest repository versions or when you have modified `apps.json`. It will force a complete fresh build of the Docker image.

# 3. Start the Keycloak SSO server (Option 1)
docker compose -f docker-compose.keycloak.yml up -d

# OR Start the Authentik SSO server (Option 2)
docker compose -f docker-compose.authentik.yml up -d
```

### 4. Access the Services
By default, the services will be available at:
- **ERPNext / Frappe**: `http://localhost:8787` (Default Admin: `Administrator` / `admin`)
- **Keycloak Admin**: `http://localhost:8686/auth` (Default Admin: `admin` / `admin`)
- **Authentik Admin**: `http://localhost:9000` (Default Admin: `akadmin` / `admin`)

---

## 🔐 SSO Integration Guides
This stack natively supports authenticating Frappe users via either Keycloak or Authentik! Read the dedicated setup guide for your preferred provider:

*   👉 **[Keycloak to Frappe Setup Guide](docs/keycloak-frappe-setup-guide.md)**
*   👉 **[Authentik to Frappe Setup Guide](docs/authentik-frappe-setup-guide.md)**

---

## 🛠️ Management Scripts
We have included robust shell scripts to manage the day-to-day operations of your stack dynamically:

- **`./logs.sh`** : Tails the logs for both the Frappe and Keycloak stacks simultaneously.
- **`./backup.sh`** : Automatically triggers a Frappe site backup and pulls the dumped SQL/files directly to your host machine in a timestamped folder.
- **`./cleanup.sh`** : Restarts containers and removes dangling or orphaned resources.
- **`./restore.sh <path>`** : Restores a Frappe database dump directly into the running database container.

---

## 🏗️ Modifying for Production
Deploying this stack to production is completely driven by your `.env` file. Do **not** manually edit the `docker-compose.keycloak.yml` or `pwd-with-apps.yml` files.

1. **Set `KC_RUN_MODE=start`**: Keycloak requires `start` to run via HTTPS and enforce security in a production environment.
2. **Ports**: Update `KC_PORT` and `FRAPPE_PORT` to `443` or use a Reverse Proxy (like NGINX, Traefik).
3. **Change All Passwords**: Ensure `*_PASSWORD` fields in your `.env` are secure and randomized.
