# My Frappe Setup Stack

A complete Docker-based deployment for **Frappe ERPNext**, **HRMS**, and **Insights**, supercharged with **Keycloak SSO**.

## Overview

This project provides a fully orchestrated stack running:
- **ERPNext** - Enterprise Resource Planning
- **Frappe HRMS** - Human Resource Management System  
- **Frappe Insights** - Business Intelligence & Analytics
- **Keycloak** - Centralized Identity Server

## Quick Start

Everything happens inside the `docker-setup` folder. Configuration is entirely driven by `.env` variables, making it trivial to swap between local development and live production hosting.

See **[docker-setup/README.md](docker-setup/README.md)** for complete installation and configuration instructions!

## Management Scripts

To make maintaining the setup easier, several utility scripts are provided inside the `docker-setup` directory:

- **`./logs.sh`** : Tails the logs for both the Frappe and Keycloak stacks simultaneously.
- **`./backup.sh`** : Automatically triggers a Frappe site backup and pulls the dumped SQL/files directly to your host machine in a timestamped folder.
- **`./cleanup.sh`** : Restarts containers and removes dangling or orphaned resources.
- **`./restore.sh <path>`** : Restores a Frappe database dump directly into the running database container.

## Project Structure

```text
my-frappe-setup/
├── docker-setup/
│   ├── .env.example             # Configuration template
│   ├── pwd-with-apps.yml        # Frappe Docker Compose
│   ├── docker-compose.keycloak.yml # Keycloak Docker Compose
│   ├── keycloak-frappe-setup-guide.md # SSO Integration Documentation
│   ├── setup.sh                 # Stack initial build and provision
│   ├── cleanup.sh               # Container cleanup utility
│   ├── backup.sh                # Container backup utility
│   ├── restore.sh               # Container restore utility
│   └── logs.sh                  # Stack logging utility
└── README.md                    # This file
```