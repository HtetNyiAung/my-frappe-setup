# Frappe ERPNext + HRMS + Insights — Docker Setup

Docker-based setup for **ERPNext**, **Frappe HRMS**, and **Frappe Insights**.

---

## Prerequisites

- **Docker Desktop** (with Docker Compose v2)
- **Git**
- At least **4 GB RAM** allocated to Docker
- Around **15 GB** free disk space for the full build

---

## Step‑by‑step installation (full stack)

1. **Install Docker Desktop**
   - On Windows: install Docker Desktop, enable **WSL2** and turn on integration for your Ubuntu/WSL distro.

2. **Open your WSL terminal**
   - Example:
     ```bash
     wsl
     ```

3. **Get this project (if you don’t have it yet)**
   - Pick a folder and clone your repo (or download the files):
     ```bash
     cd ~
     git clone <your-my-frappe-setup-repo-url> my-frappe-setup   # if using Git
     cd my-frappe-setup/docker-setup
     ```
   - If the folder already exists on your machine:
     ```bash
     cd ~/my-frappe-setup/docker-setup
     ```

4. **Ensure Git is installed in WSL**
   ```bash
   sudo apt update
   sudo apt install -y git
   ```

5. **Run the full ERPNext + HRMS + Insights setup**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
   This will:
   - Clone or update `frappe_docker`
   - Build the custom Docker image with ERPNext, HRMS, and Insights
   - Start all Docker containers using `pwd-with-apps.yml`

6. **Watch site creation logs (optional but recommended)**
   ```bash
   docker compose -f pwd-with-apps.yml logs -f create-site
   ```

7. **Open the application**
   - In your browser, go to: `http://localhost:8080`
   - Login:
     - **Username:** `Administrator`
     - **Password:** `admin`

---

## Option 1: Quick Start (ERPNext Only) — ~5 minutes

Use the official pre-built image for ERPNext only. No build required.

```bash
cd docker-setup
git clone https://github.com/frappe/frappe_docker.git
cd frappe_docker
docker compose -f pwd.yml up -d
```

Wait 3–5 minutes, then open **http://localhost:8080**  
- **Username:** `Administrator`  
- **Password:** `admin`

---

## Option 2: ERPNext + HRMS + Insights — ~20–30 minutes

Build a custom image that includes all three apps.

### 1. Ensure Docker Desktop is running

### 2. Run the setup script

```bash
cd /home/hnna/my-frappe-setup/docker-setup
chmod +x setup.sh
./setup.sh
```

This will:

1. Clone `frappe_docker` if needed  
2. Build a custom image with ERPNext, HRMS, and Insights  
3. Start all containers  

### 3. Wait for setup

Site creation takes about 5–10 minutes. Follow logs:

```bash
docker compose -f pwd-with-apps.yml logs -f create-site
```

When the site is ready, you’ll see the containers running and the UI will be available.

### 4. Access the app

Open **http://localhost:8080**

- **Username:** `Administrator`  
- **Password:** `admin`  

---

## App overview

| App | Description |
|-----|-------------|
| **ERPNext** | ERP: accounting, inventory, sales, purchases, manufacturing, projects |
| **Frappe HRMS** | HR: employees, attendance, leave, payroll, appraisals, onboarding |
| **Frappe Insights** | BI & reporting: drag-and-drop queries, charts, dashboards |

---

## Application setup flow (Docker)

- **Build & start**: `./setup.sh`  
- **Config & site creation**:
  - `configurator` writes `sites/common_site_config.json` with DB and Redis settings.
  - `create-site` waits for that config, then runs `bench new-site` and installs **ERPNext**, **HRMS**, and **Insights** on the default site (`frontend`).
- **App services**:
  - `backend` serves the Frappe/ERPNext backend on port `8000` (internal).
  - `frontend` (nginx) exposes port `8080` to your host.
  - `websocket` handles real‑time events.
  - `queue-long`, `queue-short`, and `scheduler` run background jobs and scheduled tasks.

After startup completes you can log in at `http://localhost:8080` and explore modules:

- **ERPNext**: Sales, Buying, Accounts, Stock, Manufacturing, Projects, CRM.
- **HRMS**: HR Workspace → Employees, Leave, Attendance, Payroll, Appraisals.
- **Insights**: Insights app → data sources, queries, charts, dashboards.

---

## Project documentation

Keep high‑level docs for this environment in `notes-and-docs/` at the project root, for example:

- **`architecture.md`**: layout of `frappe-bench`, Docker services, and networks.
- **`environments.md`**: local vs. future staging/production setups.
- **`operations.md`**: backup/restore, updating images, and common admin tasks.

Suggested sections inside those files:

- **Setup**: how to install prerequisites and run `./setup.sh`.
- **Apps & Features**: what ERPNext, HRMS, and Insights are used for in your context.
- **Customizations**: any custom doctypes, reports, or scripts you add.
- **Troubleshooting**: copy real errors and their fixes as you encounter them.

---

## Useful commands

```bash
# View logs
docker compose -f pwd-with-apps.yml logs -f

# Stop all containers
docker compose -f pwd-with-apps.yml down

# Start again (after first setup)
docker compose -f pwd-with-apps.yml up -d
```

---

## Troubleshooting

**Docker not running**

- Start Docker Desktop and wait until it’s fully ready.

**Port 8080 in use**

- Stop the service using 8080, or change the port in `pwd-with-apps.yml` under `frontend` → `ports` (e.g. `"8081:8080"`).

**Low memory**

- In Docker Desktop: Settings → Resources → increase Memory to at least 4 GB.

**Build fails**

- Ensure stable internet for cloning and building.
- On ARM (e.g. M1/M2): the custom build should work; if it fails, you may need to add `platform: linux/amd64` for some images.