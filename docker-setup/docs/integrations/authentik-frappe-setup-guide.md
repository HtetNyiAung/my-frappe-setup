# Authentik Setup Guide for Frappe/ERPNext

This guide explains the Authentik identity provider setup included in this repository and the step-by-step process to configure Single Sign-On (SSO) between Authentik and Frappe/ERPNext for the `my-frappe-setup` project.

## Overview

The `docker-compose.authentik.yml` file provisions a complete [Authentik](https://goauthentik.io/) stack. Authentik is an open-source Identity Provider (IdP) that you can use to manage authentication, SSO (Single Sign-On), and user identities for your Frappe applications or other services.

## Architecture

The setup relies on the following Docker services:

1. **`authentik-db`** (PostgreSQL): Stores all of Authentik's configuration, users, and tokens.
2. **`authentik-redis`** (Redis): Used for caching, session management, and background task queuing.
3. **`authentik-server`** (Authentik): The main web server that serves the UI and handles authentication requests/API calls.
4. **`authentik-worker`** (Authentik): The background processor that handles tasks like email sending, synchronization, and cleanup.

> **Note:** The Authentik stack is connected to the `frappe_network` (external network) so that Frappe/ERPNext containers can securely communicate directly with the Authentik instance for SSO integrations.

## Prerequisites

Before starting Authentik, ensure your `.env` file has the necessary variables configured:

```env
# Authentik Configuration
AUTHENTIK_PORT=9000
AUTHENTIK_HTTPS_PORT=9443
AUTHENTIK_DB_PASSWORD=authentik_db_password
AUTHENTIK_DB_NAME=authentik
AUTHENTIK_DB_USER=authentik
# RUN: openssl rand -base64 64 | tr -d '\n' to generate a secret key
AUTHENTIK_SECRET_KEY=yoursecretkey_replacethis
AUTHENTIK_TAG=2024.12.3
# Initial login credentials
AUTHENTIK_BOOTSTRAP_PASSWORD=admin
AUTHENTIK_BOOTSTRAP_EMAIL=admin@example.com
```

*   **`AUTHENTIK_SECRET_KEY`**: This is critical for security. Make sure you generate a strong, unique secret key. If you change this later, existing sessions and some encrypted configurations may become corrupted.
*   **`AUTHENTIK_PORT`**: The default port mapping for the Authentik UI (HTTP). By default, this maps to `9000` on the host.

## Step-by-Step Configuration

### Step 1: Start Authentik & Frappe Containers

To start both the Frappe stack and the Authentik stack detached (in the background), you can run:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.authentik.yml up -d
```

*(Alternatively, to run just Authentik isolated:* `docker compose -f docker-compose.authentik.yml --env-file .env up -d`*)*

*Note: The first time you start up, the `authentik-server` container will say "authentik starting" for a few minutes while it provisions the database. You can monitor progress with `docker logs -f authentik-server`.*

### Step 2: Accessing the Dashboard

Ensure both Frappe (Port `8787`) and Authentik (Port `9000`) containers are running. 
Once the services are fully started, you can access the dashboard at:
*   [http://localhost:9000/](http://localhost:9000/)

Log in using the default `akadmin` superuser and the credentials you configured in your `.env` file:
*   **Username**: `akadmin` (or the email defined in `AUTHENTIK_BOOTSTRAP_EMAIL`)
*   **Password**: The value of `AUTHENTIK_BOOTSTRAP_PASSWORD` in your `.env` file.

*(Note: If you didn't set bootstrap credentials in your `.env` file, you must go to [http://localhost:9000/if/flow/initial-setup/](http://localhost:9000/if/flow/initial-setup/) to set the `akadmin` password manually.)*

## Volumes & State

State is stored using standard Docker named volumes and local mounts:
*   `authentik_db_data`: PostgreSQL database persistence.
*   `authentik_redis_data`: Redis cache persistence.
*   `./authentik_media`: Holds custom branding media / icons uploaded to Authentik.
*   `./authentik_custom_templates`: Holds override templates for the Authentik UI.
*   `./authentik_certs`: Holds certificates / keys generated or uploaded to Authentik.

## Troubleshooting

### Reset `akadmin` Password

If you forgot your `akadmin` password or need to recover admin access, run the following command to interactively set a new password:

```bash
docker compose -f docker-compose.authentik.yml exec authentik-server python3 manage.py changepassword akadmin
```

> **Note:** This command will prompt you to enter and confirm the new password in your terminal. The Authentik server container must be running for this to work.

### Fix Permission Denied on `/media/public`

If `authentik-server` fails with `PermissionError: [Errno 13] Permission denied: '/media/public'`, fix the folder permissions from the host:

```bash
sudo chmod -R 777 ./authentik_media ./authentik_certs ./authentik_custom_templates
docker restart authentik-server authentik-worker
```

---

## Additional Commands

### Stopping Authentik
To stop the stack without losing data:

```bash
docker compose -f docker-compose.authentik.yml stop
```

### Tearing Down Authentik
To remove the containers (your database data will persist in Docker volumes unless you add the `-v` flag):

```bash
docker compose -f docker-compose.authentik.yml down
```
