# My Frappe Setup

Docker-based setup for Frappe ERPNext, HRMS, and Insights.

## Overview

This project contains a complete Docker setup for running:
- **ERPNext** - Enterprise Resource Planning
- **Frappe HRMS** - Human Resource Management System  
- **Frappe Insights** - Business Intelligence & Analytics

## Quick Start

See `docker-setup/README.md` for detailed installation instructions.

## Project Structure

```
my-frappe-setup/
├── docker-setup/
│   ├── README.md          # Detailed setup guide
│   ├── setup.sh           # Installation script
│   ├── pwd-with-apps.yml  # Docker Compose configuration
│   └── frappe_docker/     # Frappe Docker repository
└── README.md              # This file
```

## Documentation

- **Installation & Setup**: `docker-setup/README.md`
- **Docker Configuration**: `docker-setup/pwd-with-apps.yml`
- **Setup Script**: `docker-setup/setup.sh`

## Access

After setup, applications are available at:
- **URL**: http://localhost:8080
- **Username**: Administrator
- **Password**: admin