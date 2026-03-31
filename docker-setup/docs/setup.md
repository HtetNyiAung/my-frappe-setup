# Setup Script (`setup.sh`)

The `setup.sh` script is the primary installation and initialization utility for the Frappe stack. It automates the building of the custom Docker image and the provisioning of the initial ERPNext site.

## What it does

1.  **Environment Check**: Verifies the presence of a `.env` file for configuration.
2.  **Repository Sync**: Clones or updates the official `frappe_docker` repository which provides the build templates.
3.  **Custom Image Build**: 
    -   Reads your `apps.json` file.
    -   Builds a custom Frappe Docker image (tagged as `CUSTOM_IMAGE` in `.env`) containing **ERPNext**, **HRMS**, and **Insights**.
4.  **Orchestration**: Starts the Frappe containers using `docker compose`.
5.  **Site Provisioning**:
    -   Automatically checks if the site defined in `SITE_DOMAIN` already exists.
    -   If it's a **new site**: Creates the site, sets the admin password, and installs the necessary apps.
    -   If it's an **existing site**: Runs database migrations and ensures apps are installed.

## Usage

```bash
chmod +x setup.sh
./setup.sh
```

## Prerequisites

-   A properly configured `.env` file.
-   An `apps.json` file listing the desired Frappe applications.
-   Docker and Docker Compose installed and running.

## Environment Variables Used

-   `STACK_ID`: Used as the project name.
-   `CUSTOM_IMAGE`: The tag for the local Docker image.
-   `FRAPPE_BRANCH`: Which version of Frappe to build (e.g., `version-16`).
-   `COMPOSE_FILE`: Usually `pwd-with-apps.yml`.
-   `SITE_DOMAIN`: The name/URL of the Frappe site to create.
-   `ADMIN_PASSWORD`: Password for the `Administrator` user.
-   `MYSQL_ROOT_PASSWORD`: Required for database creation.

## Verifying the Setup

After setup is complete, you should verify if all the apps are installed correctly. Run the following command:

```bash
docker compose exec backend bench --site <your-site-domain> list-apps
```

This will list all the installed Frappe and ERPNext applications on your site.
