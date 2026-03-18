# My Frappe Stack + Keycloak SSO

A complete, production-ready, Docker-based deployment stack configured for **Frappe ERPNext**, **HRMS**, **Insights**, and secured with a dedicated **Keycloak SSO** authenticator.

## Overview

This repository uses Docker Compose to orchestrate:
- **Frappe Framework** (ERPNext, HRMS, Insights - v16)
- **MariaDB** (Database)
- **Redis** (Cache & Queue)
- **Keycloak** (Identity & Access Management SSO)
- **PostgreSQL** (Keycloak-specific Database)

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

### 3. Start the Stack
You can start Frappe and Keycloak independently, or all at once:

```bash
# Start Frappe apps
docker compose -f pwd-with-apps.yml up -d

# Start Keycloak SSO server
docker compose -f docker-compose.keycloak.yml up -d
```

### 4. Access the Services
By default, the services will be available at:
- **ERPNext / Frappe**: `http://localhost:8787` (Default Admin: `Administrator` / `admin`)
- **Keycloak Admin**: `http://localhost:8686/auth` (Default Admin: `admin` / `admin`)

---

## 🔐 Keycloak SSO Integration
This stack natively supports authenticating Frappe users via Keycloak!

If you are setting this up for the first time or need to rebuild the SSO bridge, read the dedicated guide located here:
👉 **[Keycloak to Frappe Setup Guide](keycloak-frappe-setup-guide.md.resolved)**

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
