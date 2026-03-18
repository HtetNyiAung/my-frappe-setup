# My Frappe Setup Stack

A complete Docker-based deployment for **Frappe ERPNext**, **HRMS**, and **Insights**, supercharged with **Keycloak SSO**.

## Overview

This project provides a fully orchestrated stack running:
- **ERPNext** - Enterprise Resource Planning
- **Frappe HRMS** - Human Resource Management System  
- **Frappe Insights** - Business Intelligence & Analytics
- **Keycloak** - Centralized Identity Server

---

## Step 1: Install Docker

### Option A: Windows (Docker Desktop)

1. Download and install **Docker Desktop** from [docker.com](https://www.docker.com/products/docker-desktop)
2. Enable **WSL2** and turn on integration for your Ubuntu/WSL distro
3. Start Docker Desktop

### Option B: Ubuntu Server

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git

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

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker compose version
```

---

## Quick Start

Everything happens inside the `docker-setup` folder. Configuration is entirely driven by `.env` variables, making it trivial to swap between local development and live production hosting.

See **[docker-setup/README.md](docker-setup/README.md)** for complete installation and configuration instructions!

## Management Scripts

To make maintaining the setup easier, several utility scripts are provided inside the `docker-setup` directory:

- **[`./logs.sh`](docker-setup/docs/logs.md)** : Tails the logs for both the Frappe and Keycloak stacks simultaneously.
- **[`./backup.sh`](docker-setup/docs/backup.md)** : Automatically triggers a Frappe site backup and pulls the dumped SQL/files directly to your host machine in a timestamped folder.
- **[`./cleanup.sh`](docker-setup/docs/cleanup.md)** : Restarts containers and removes dangling or orphaned resources.
- **[`./restore.sh <path>`](docker-setup/docs/restore.md)** : Restores a Frappe database dump directly into the running database container.

## Project Structure

```text
my-frappe-setup/
├── docker-setup/
│   ├── .env.example             # Configuration template
│   ├── pwd-with-apps.yml        # Frappe Docker Compose
│   ├── docker-compose.keycloak.yml # Keycloak Docker Compose
│   ├── docs/                    # Extensive documentation
│   │   ├── keycloak-frappe-setup-guide.md
│   │   ├── setup.md
│   │   ├── backup.md
│   │   ├── restore.md
│   │   ├── logs.md
│   │   └── cleanup.md
│   ├── setup.sh                 # Stack initial build and provision
│   ├── cleanup.sh               # Container cleanup utility
│   ├── backup.sh                # Container backup utility
│   ├── restore.sh               # Container restore utility
│   └── logs.sh                  # Stack logging utility
└── README.md                    # This file
```