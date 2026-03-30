# Authentik Setup Guide for Frappe/ERPNext

This guide explains the step-by-step process to configure Single Sign-On (SSO) between Authentik and Frappe/ERPNext for the `my-frappe-setup` project.

## Prerequisites
- Ensure the `.env` file is configured with `AUTHENTIK_SECRET_KEY` and other necessary environment variables.
- Ensure both Frappe (Port `8787`) and Authentik (Port `9000`) containers are running.

---

## Step 1: Start Authentik Containers
Start the required database and Redis containers for Authentik.

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.authentik.yml up -d
