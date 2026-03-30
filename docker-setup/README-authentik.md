# Authentik Setup Guide

This document explains the Authentik identity provider setup included in this repository.

## Overview

The `docker-compose.authentik.yml` file provisions a complete [Authentik](https://goauthentik.io/) stack. Authentik is an open-source Identity Provider (IdP) that you can use to manage authentication, SSO (Single Sign-On), and user identities for your Frappe applications or other services.

## Architecture

The setup relies on the following Docker services:

1. **`authentik-db`** (PostgreSQL): Stores all of Authentik's configuration, users, and tokens.
2. **`authentik-redis`** (Redis): Used for caching, session management, and background task queuing.
3. **`authentik-server`** (Authentik): The main web server that serves the UI and handles authentication requests/API calls.
4. **`authentik-worker`** (Authentik): The background processor that handles tasks like email sending, synchronization, and cleanup.

> **Note:** The Authentik stack is connected to the `frappe_network` (external network) so that Frappe/ERPNext containers can securely communicate directly with the Authentik instance for SSO integrations.

## Environment Variables

Before starting Authentik, ensure your `.env` file has the necessary variables. An example of the required variables (which can be found in `.env.example`) is:

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
```

*   **`AUTHENTIK_SECRET_KEY`**: This is critical for security. Make sure you generate a strong, unique secret key. If you change this later, existing sessions and some encrypted configurations may become corrupted.
*   **`AUTHENTIK_PORT`**: The default port mapping for the Authentik UI (HTTP). By default, this maps to `9000` on the host.

## Usage Commands

### 1. Starting Authentik
To start the Authentik stack detached (in the background), run:

```bash
docker compose -f docker-compose.authentik.yml --env-file .env up -d
```
*Note: The first time you start up, the `authentik-server` container will say "authentik starting" for a few minutes while it provisions the database. You can monitor progress with `docker logs -f authentik-server`.*

### 2. Accessing the Dashboard
Once the services are fully started, you can access the initial setup and dashboard at:
*   [http://localhost:9000/if/flow/initial-setup/](http://localhost:9000/if/flow/initial-setup/)

This initial setup flow will prompt you to configure the `akadmin` user (the default superuser account).

### 3. Stopping Authentik
To stop the stack without losing data:

```bash
docker compose -f docker-compose.authentik.yml stop
```

### 4. Tearing Down Authentik
To remove the containers (your database data will persist in Docker volumes unless you add the `-v` flag):

```bash
docker compose -f docker-compose.authentik.yml down
```

## Volumes & State

State is stored using standard Docker named volumes and local mounts:
*   `authentik_db_data`: PostgreSQL database persistence.
*   `authentik_redis_data`: Redis cache persistence.
*   `./authentik_media`: Holds custom branding media / icons uploaded to Authentik.
*   `./authentik_custom_templates`: Holds override templates for the Authentik UI.
*   `./authentik_certs`: Holds certificates / keys generated or uploaded to Authentik. 
