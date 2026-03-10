# Frappe ERPNext + HRMS + Insights — Docker Setup

Docker-based setup for **ERPNext**, **Frappe HRMS**, and **Frappe Insights**.

---

## Prerequisites

- **4 GB RAM** minimum (8 GB recommended for production)
- **15 GB** free disk space
- **Internet connection** for downloading packages

---

## Step 1: Install Docker

### Option A: Windows (Docker Desktop)

1. Download and install **Docker Desktop** from https://www.docker.com/products/docker-desktop
2. Enable **WSL2** and turn on integration for your Ubuntu/WSL distro
3. Start Docker Desktop

### Option B: Ubuntu Server

```bash
# Update system packages
sudo apt update
sudo apt upgrade -y

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

# Configure Docker
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
docker compose version
```

---

## Step 2: Clone and Setup

```bash
# Clone this repository
git clone <your-my-frappe-setup-repo-url> my-frappe-setup
cd my-frappe-setup/docker-setup

# Run setup script
chmod +x setup.sh
./setup.sh
```

---

## Step 3: Configure IP Binding

By default, the application binds to `localhost:8080`. To access from other devices on your network:

### Edit Docker Compose Configuration

1. Open `pwd-with-apps.yml` in a text editor
2. Find the `frontend` service section
3. Modify the ports binding:

**Current (localhost only):**
```yaml
frontend:
  ports:
    - "8080:8080"
```

**For network access (bind to all interfaces):**
```yaml
frontend:
  ports:
    - "0.0.0.0:8080:8080"
```

**For specific IP (xxx.xxx.xx.xxx):**
```yaml
frontend:
  ports:
    - "xxx.xxx.xx.xxx:8080:8080"
```

4. Save the file and restart containers:

```bash
# Stop existing containers
docker compose -f pwd-with-apps.yml down

# Start with new configuration
docker compose -f pwd-with-apps.yml up -d
```

---

## Step 4: Access the Application

### Local Access
- **URL**: http://localhost:8080
- **Username**: Administrator
- **Password**: admin

### Network Access
- **URL**: http://xxx.xxx.xx.xxx:8080
- **Username**: Administrator
- **Password**: admin

---

## Production Configuration

### Database Security

Edit `pwd-with-apps.yml` and replace default passwords:

```yaml
services:
  db:
    environment:
      - MYSQL_ROOT_PASSWORD=your_secure_root_password
      - MYSQL_USER=erpnext
      - MYSQL_PASSWORD=your_secure_user_password
      - MYSQL_DATABASE=erpnext

  configurator:
    environment:
      - DB_ROOT_PASSWORD=your_secure_root_password
      - DB_PASSWORD=your_secure_user_password
      - ADMIN_PASSWORD=your_admin_password
```

### Security Checklist

- [ ] Change all default passwords
- [ ] Use strong passwords (12+ characters)
- [ ] Configure firewall (allow ports 80, 443, 8080)
- [ ] Set up SSL/HTTPS for production
- [ ] Configure regular backups
- [ ] Monitor system resources

---

## Useful Commands

```bash
# View logs
docker compose -f pwd-with-apps.yml logs -f

# Stop all containers
docker compose -f pwd-with-apps.yml down

# Start containers
docker compose -f pwd-with-apps.yml up -d

# Check container status
docker compose -f pwd-with-apps.yml ps
```

---

## Troubleshooting

**Port 8080 in use**
- Stop the service using port 8080, or change the port in `pwd-with-apps.yml`

**Can't access from network**
- Check firewall settings: `sudo ufw status`
- Verify IP binding in `pwd-with-apps.yml`
- Ensure Docker is running: `sudo systemctl status docker`

**Build fails**
- Ensure stable internet connection
- Check available disk space: `df -h`
- Verify Docker service is running

---

## Adding New Frappe Modules

Yes! You can easily add new Frappe modules (like Frappe Lending, Learning, etc.) to your setup.

### Method 1: Update apps.json (Recommended)

1. **Edit `apps.json`** in the docker-setup directory:

```json
{
  "apps": [
    {
      "url": "https://github.com/frappe/erpnext",
      "branch": "version-15"
    },
    {
      "url": "https://github.com/frappe/hrms",
      "branch": "version-15"
    },
    {
      "url": "https://github.com/frappe/insights",
      "branch": "version-15"
    },
    {
      "url": "https://github.com/frappe/lending",
      "branch": "version-15"
    }
  ]
}
```

2. **Rebuild and restart**:

```bash
# Stop existing containers
docker compose -f pwd-with-apps.yml down

# Rebuild with new apps
./setup.sh

# Or manually rebuild
docker compose -f pwd-with-apps.yml build --no-cache
docker compose -f pwd-with-apps.yml up -d
```

### Method 2: Add via Bench (After Setup)

1. **Access the container**:
```bash
docker compose -f pwd-with-apps.yml exec backend bash
```

2. **Install new app**:
```bash
cd /workspace
bench get-app https://github.com/frappe/lending
bench install-app lending
bench --site frontend migrate
```

3. **Exit and restart**:
```bash
exit
docker compose -f pwd-with-apps.yml restart
```

### Popular Frappe Apps

| App | Purpose | GitHub URL |
|-----|---------|------------|
| **Frappe Lending** | Loan management, credit scoring | `https://github.com/frappe/lending` |
| **Frappe Learning** | LMS, courses, training | `https://github.com/frappe/education` |
| **Frappe Helpdesk** | Customer support, tickets | `https://github.com/frappe/helpdesk` |
| **Frappe CRM** | Customer relationship management | `https://github.com/frappe/crm` |
| **Frappe Payments** | Payment gateways integration | `https://github.com/frappe/payments` |
| **Frappe Builder** | No-code app builder | `https://github.com/frappe/builder` |

### Important Notes

- **Version Compatibility**: Ensure the app branch matches your ERPNext version (usually `version-15`)
- **Build Time**: Adding new apps requires rebuilding the Docker image (15-30 minutes)
- **Dependencies**: Some apps may require additional configuration
- **Database**: New apps will automatically create necessary database tables

### Quick Example: Adding Frappe Lending

1. Add to `apps.json`:
```json
{
  "url": "https://github.com/frappe/lending",
  "branch": "version-15"
}
```

2. Run setup:
```bash
./setup.sh
```

3. Access Lending module in ERPNext under **Modules > Lending**

---

## Applications Overview

| Application | Description |
|-------------|-------------|
| **ERPNext** | ERP: accounting, inventory, sales, purchases, manufacturing |
| **Frappe HRMS** | HR: employees, attendance, leave, payroll, appraisals |
| **Frappe Insights** | BI & reporting: queries, charts, dashboards |

## Prerequisites

- **Ubuntu 20.04+** or **Debian 10+** server
- At least **4 GB RAM** (8 GB recommended for production)
- Around **15 GB** free disk space for the full build
- **sudo** access on the server
- Internet connection for downloading packages

---

## Server Installation Guide

### 1. Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Required Dependencies

```bash
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    wget \
    htop \
    unzip
```

### 3. Install Docker

```bash
# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index and install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### 4. Configure Docker

```bash
# Add your user to the docker group (replace 'username' with your actual username)
sudo usermod -aG docker username

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify Docker installation
docker --version
docker compose version
```

### 5. Configure Firewall (if UFW is enabled)

```bash
# Allow SSH, HTTP, and HTTPS
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp  # For ERPNext access

# Enable firewall
sudo ufw enable
```

### 6. Optimize System for Production

```bash
# Increase file limits for production
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize memory management
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Create swap file if needed (4GB)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Step‑by‑step installation (full stack)

1. **Clone this repository**
   ```bash
   cd /opt
   sudo git clone <your-my-frappe-setup-repo-url> my-frappe-setup
   sudo chown -R $USER:$USER /opt/my-frappe-setup
   cd my-frappe-setup/docker-setup
   ```

2. **Run the full ERPNext + HRMS + Insights setup**
   ```bash
   chmod +x setup.sh
   ./setup.sh
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

## Production Configuration

### Database Configuration

For production deployments, modify the database settings in `pwd-with-apps.yml`:

```yaml
services:
  db:
    environment:
      - MYSQL_ROOT_PASSWORD=your_secure_root_password
      - MYSQL_USER=erpnext
      - MYSQL_PASSWORD=your_secure_user_password
      - MYSQL_DATABASE=erpnext
```

**Important:** Replace the default passwords with secure values before deploying to production.

### Environment Variables

Edit the following in `pwd-with-apps.yml` for production:

```yaml
services:
  configurator:
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - DB_ROOT_USER=root
      - DB_ROOT_PASSWORD=your_secure_root_password
      - DB_NAME=erpnext
      - DB_USER=erpnext
      - DB_PASSWORD=your_secure_user_password
      - ADMIN_PASSWORD=your_admin_password
```

### Security Considerations

- **Change all default passwords** before production deployment
- **Use strong passwords** with at least 12 characters including uppercase, lowercase, numbers, and symbols
- **Consider using Docker secrets** for sensitive data in production
- **Update ADMIN_PASSWORD** for the default Administrator user
- **Configure SSL/HTTPS** for production deployments
- **Set up proper backups** for database and file storage

### Business Logic Configuration

After deployment, configure business-specific settings in the ERPNext UI:

1. **Company Settings**: Setup your company details, fiscal year, and currency
2. **User Management**: Create user accounts with appropriate roles
3. **Email Settings**: Configure SMTP for email notifications
4. **Backup Settings**: Set up automated backup schedules
5. **Custom Fields**: Add business-specific fields to documents as needed

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