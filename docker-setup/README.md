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
# 1. Clone this repository
git clone <your-my-frappe-setup-repo-url> my-frappe-setup
cd my-frappe-setup/docker-setup

# 2. Prepare Environment Variables
# Copy the example file and edit it with your specific IP (192.168.97.105) and ports
cp .env.example .env
nano .env  # or use any editor to fill in your passwords and BIND_ADDRESS

# 3. Run setup script
chmod +x setup.sh logs.sh cleanup.sh backup.sh restore.sh
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

## User and Employee Account Setup

### Creating User Accounts and Binding with Employee Records

To allow users to login to the HR mobile app and web interface, you need to create user accounts and bind them to employee records.

#### Step 1: Create User Account

1. **Login as Administrator** to ERPNext
2. Go to **System > User > User** or navigate to `/app/user`
3. Click **"Add User"** and fill in:
   - **Email**: User's email address (this will be the login username)
   - **First Name** and **Last Name**
   - **Enabled**: Check this box
   - **Send Password**: Check to email password to user
   - **Role**: Select appropriate role (usually "Employee" for HR access)

#### Step 2: Create Employee Record

1. Go to **HR > Employee > Employee** or navigate to `/app/employee`
2. Click **"Add Employee"** and fill in:
   - **First Name**, **Last Name**
   - **Employee ID**: Unique identifier
   - **Company**: Select your company
   - **Department**: Select department
   - **Designation**: Job title
   - **Date of Joining**: Employment start date
   - **Email**: Same email as user account
   - **Phone**: Contact number

#### Step 3: Bind User to Employee

**Method A: From Employee Record**

1. Open the Employee record you created
2. In the **"User"** field, select the user account you created
3. Save the Employee record

**Method B: From User Record**

1. Open the User record
2. Go to the **"Employee"** tab
3. Link to the existing Employee record
4. Save the User record

#### Step 4: Set Password and Enable Login

1. Open the User record
2. Scroll to **"Password"** section
3. Set a secure password or use "Send Password" to email reset link
4. Ensure **"Enabled"** checkbox is checked
5. Save the record

#### Step 5: Test Login

1. **Web Access**: Go to http://xxx.xxx.xx.xxx:8080
2. **Mobile HR Access**: Go to http://xxx.xxx.xx.xxx:8080/hrms/home
3. Login with:
   - **Username**: User's email address
   - **Password**: The password you set

#### Bulk User Creation

For multiple employees, you can use:

**Data Import Method**:
1. Go to **Data Import** in ERPNext
2. Select **"User"** doctype
3. Upload CSV with user details
4. Repeat for **"Employee"** doctype
5. Use **"Link Existing"** option to bind users to employees

#### Important Notes

- **Email Matching**: User email and Employee email must match exactly
- **Unique Emails**: Each user must have a unique email address
- **Role Permissions**: Assign appropriate roles based on job responsibilities
- **Password Policy**: Enforce strong passwords for security
- **Mobile Access**: Once bound, users can immediately access HR mobile features

#### Common Issues

**"Invalid Login" Error**:
- Check if user account is enabled
- Verify password is correct
- Ensure user is bound to employee record

**"Access Denied" on Mobile**:
- Verify user has "Employee" role
- Check if user is linked to active employee record
- Ensure employee status is "Active"

**Missing HR Modules**:
- Go to **Role Permission Manager**
- Ensure Employee role has access to HR modules

---

## Development Setup

### Container Architecture for Customization

This Docker setup is designed for seamless development and customization:

**Apps Volume Mounting:**
- The `apps` folder is mounted to the backend container at `/home/frappe/frappe-bench/apps/`
- This allows real-time code editing and customizations
- Changes made to app files are immediately available in the container

**Development Workflow:**
```bash
# Copy apps to local for editing
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/. ./apps/

# Edit files locally with your preferred IDE
# Changes can be copied back to container
docker cp ./apps/. $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/
```

**Contribution Ready:**
- All Frappe apps are accessible for customization
- Custom apps can be added to the `apps.json` configuration
- Development environment mirrors production setup

---

## Access Links

### Application URLs

**Desktop Interface (Full ERP):**
- **URL**: http://localhost:8080
- **Access**: Complete ERPNext, HRMS, and Insights modules
- **Best for**: Administrative tasks, configuration, full-featured work

**Mobile Portal (HR Focus):**
- **URL**: http://localhost:8080/hrms
- **Access**: Mobile-optimized HR interface
- **Best for**: Employee self-service, attendance, leave requests

**Network Access:**
- **URL**: http://xxx.xxx.xx.xxx:8080 (replace with your server IP)
- **Mobile HR**: http://xxx.xxx.xx.xxx:8080/hrms

---

## Cheat Sheet

### Essential Docker & Bench Commands

#### Container Management
```bash
# Start all services
docker compose -f pwd-with-apps.yml up -d

# Stop all services
docker compose -f pwd-with-apps.yml down

# View container status
docker compose -f pwd-with-apps.yml ps

# View logs
docker compose -f pwd-with-apps.yml logs -f

# Access backend container shell
docker compose -f pwd-with-apps.yml exec backend bash
```

#### Bench Commands (Inside Container)
```bash
# Database migration (after updates)
bench --site frontend migrate

# Database backup
bench --site frontend backup

# Database restore
bench --site frontend restore [backup_file]

# Health check
bench --site frontend doctor

# List installed apps
bench --site frontend list-apps

# Build assets (after UI changes)
bench build

# Create new site
bench new-site [site_name]

# Install app
bench --site frontend install-app [app_name]

# Reset admin password
bench --site frontend set-admin-password [new_password]
```

#### Development Commands
```bash
# Switch to branch
bench switch-to-branch [branch_name] [app_name]

# Update apps
bench update --patch

# Restart services
bench restart

# Clear cache
bench --site frontend clear-cache
```

---

## Best Practices

### Data Safety During Operations

**Version Upgrade Workflow:**
1. **Backup** → Always backup before any changes
   ```bash
   bench --site frontend backup
   ```

2. **Pull** → Update app versions in apps.json, then pull
   ```bash
   ./setup.sh
   ```

3. **Migrate** → Run database migrations
   ```bash
   bench --site frontend migrate
   ```

**Development Safety:**
- Test customizations in development environment first
- Keep backups of custom code before updates
- Use version control for custom apps
- Document all custom modifications

**Production Guidelines:**
- Regular automated backups
- Monitor system performance
- Keep security patches updated
- Test updates in staging environment

**Resource Management:**
- Monitor Docker container resource usage
- Clean up unused Docker images periodically
- Keep adequate disk space for backups
- Monitor database size and performance

---

## Quick Upgrade (Data Safe)

### Upgrade Version Without Losing Data - 5 Minute Guide

**Step 1: Backup Data**
```bash
# Backup database
docker compose -f pwd-with-apps.yml exec backend bash
cd /home/frappe/frappe-bench
bench --site frontend backup
exit
```

**Step 2: Update apps.json**
```json
{
  "apps": [
    {
      "url": "https://github.com/frappe/erpnext",
      "branch": "version-15"  // Update to newer version
    },
    {
      "url": "https://github.com/frappe/hrms", 
      "branch": "version-15"  // Update to newer version
    }
  ]
}
```

**Step 3: Run Update**
```bash
# Stop containers (data preserved in volumes)
docker compose -f pwd-with-apps.yml down

# Update with data preservation
./setup.sh

# Start with existing data
docker compose -f pwd-with-apps.yml up -d
```

**Step 4: Verify**
```bash
# Check data integrity
docker compose -f pwd-with-apps.yml exec backend bash
bench --site frontend migrate
bench --site frontend doctor
exit
```

🔒 **Your data is safe** - Docker volumes preserve all database and file data during upgrades.

---

## Version Update Guide

### Updating Frappe, ERPNext, HRMS, and Insights

This guide shows how to update your Frappe setup while preserving your customizations, data, and fixes.

#### Before Updating - Backup Everything

**1. Backup Database:**
```bash
# Enter backend container
docker compose -f pwd-with-apps.yml exec backend bash

# Backup database
cd /home/frappe/frappe-bench
bench --site frontend backup

# Exit container
exit
```

**2. Backup Apps and Customizations:**
```bash
# Copy all apps to local backup
mkdir -p backup/$(date +%Y%m%d)
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/. ./backup/$(date +%Y%m%d)/apps/

# Copy custom files
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/sites/. ./backup/$(date +%Y%m%d)/sites/
```

**3. Backup Docker Configuration:**
```bash
cp pwd-with-apps.yml ./backup/$(date +%Y%m%d)/
cp apps.json ./backup/$(date +%Y%m%d)/
```

#### Update Methods

### Method 1: Safe Update (Recommended)

**1. Update apps.json with new versions:**
```json
{
  "apps": [
    {
      "url": "https://github.com/frappe/erpnext",
      "branch": "version-15"  // Change to latest version
    },
    {
      "url": "https://github.com/frappe/hrms", 
      "branch": "version-15"  // Change to latest version
    },
    {
      "url": "https://github.com/frappe/insights",
      "branch": "version-15"  // Change to latest version
    }
  ]
}
```

**2. Update with data preservation:**
```bash
# Stop containers
docker compose -f pwd-with-apps.yml down

# Pull latest images
docker compose -f pwd-with-apps.yml pull

# Update with data preservation
./setup.sh

# Start containers
docker compose -f pwd-with-apps.yml up -d
```

### Method 2: Manual Update (Advanced)

**1. Access container and update:**
```bash
docker compose -f pwd-with-apps.yml exec backend bash
cd /home/frappe/frappe-bench

# Update apps
bench update --patch

# Or update to specific version
bench switch-to-branch version-15 frappe
bench switch-to-branch version-15 erpnext
bench switch-to-branch version-15 hrms
bench switch-to-branch version-15 insights

# Migrate database
bench --site frontend migrate

# Build assets
bench build

exit
```

#### Preserving Customizations During Update

### 1. Custom App Files

**Before Update:**
```bash
# Create custom apps directory
mkdir -p custom_apps

# Copy your custom modifications
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/custom_app/. ./custom_apps/
```

**After Update:**
```bash
# Copy custom apps back
docker cp ./custom_apps/. $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/

# Reinstall custom app
docker compose -f pwd-with-apps.yml exec backend bash
cd /home/frappe/frappe-bench
bench --site frontend install-app custom_app
bench --site frontend migrate
exit
```

### 2. UI Customizations

**Backup Custom CSS/JS:**
```bash
# Backup custom CSS
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/frappe/frappe/public/css/custom.css ./backup/

# Backup custom JS
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/frappe/frappe/public/js/custom.js ./backup/
```

**Restore After Update:**
```bash
# Restore custom files
docker cp ./backup/custom.css $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/frappe/frappe/public/css/
docker cp ./backup/custom.js $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/frappe/frappe/public/js/
```

### 3. Configuration Files

**Backup Site Config:**
```bash
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/sites/common_site_config.json ./backup/
```

**Restore After Update:**
```bash
docker cp ./backup/common_site_config.json $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/sites/
```

#### Post-Update Checklist

### 1. Verify Applications
```bash
# Check all apps are working
docker compose -f pwd-with-apps.yml exec backend bash
cd /home/frappe/frappe-bench
bench --site frontend doctor

# Check app versions
bench --site frontend list-apps
exit
```

### 2. Test Key Features
- [ ] Login works for all users
- [ ] HR mobile app accessible
- [ ] ERPNext modules functioning
- [ ] Reports and dashboards working
- [ ] Custom features still work
- [ ] Email notifications working

### 3. Performance Check
```bash
# Check container status
docker compose -f pwd-with-apps.yml ps

# Check logs for errors
docker compose -f pwd-with-apps.yml logs --tail=50
```

#### Rollback Plan (If Update Fails)

**1. Quick Rollback:**
```bash
# Stop containers
docker compose -f pwd-with-apps.yml down

# Restore previous configuration
cp backup/$(date +%Y%m%d)/pwd-with-apps.yml ./
cp backup/$(date +%Y%m%d)/apps.json ./

# Restore database
docker compose -f pwd-with-apps.yml up -d db
# Wait for DB to be ready, then restore from backup file
```

**2. Complete Rollback:**
```bash
# Stop everything
docker compose -f pwd-with-apps.yml down -v

# Remove all containers and images
docker system prune -a

# Rebuild from scratch with backup data
./setup.sh
```

#### Important Notes

- **Test First**: Always test updates in development environment
- **Backup Mandatory**: Never update without proper backups
- **Version Compatibility**: Ensure all apps use compatible versions
- **Custom Apps**: Custom apps may need updates for new Frappe versions
- **Database Changes**: Major version updates may require database migration
- **Performance**: Monitor system performance after updates

#### Update Schedule Recommendations

- **Minor Updates**: Every 2-3 months for security patches
- **Major Updates**: Every 6-12 months for new features
- **Custom Apps**: Update custom apps after core updates
- **Backup Rotation**: Keep backups for at least 30 days

---

## Development and Customization

### Accessing App Files for Code/UI Modification

You can copy Frappe apps from the Docker container to your local machine for development, customization, or code inspection.

#### Copy Apps from Container

```bash
# Copy all apps to local directory
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/. ./apps/

# Copy specific app (e.g., ERPNext only)
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/erpnext/. ./erpnext/

# Copy HRMS app only
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/hrms/. ./hrms/
```

#### What You Can Modify

**UI Customizations:**
- HTML templates in `apps/[app_name]/[app_name]/templates/`
- CSS files in `apps/[app_name]/[app_name]/public/css/`
- JavaScript files in `apps/[app_name]/[app_name]/public/js/`
- Page layouts and views

**Code Customizations:**
- Python models in `apps/[app_name]/[app_name]/doctype/`
- API endpoints in `apps/[app_name]/[app_name]/api/`
- Business logic in `apps/[app_name]/[app_name]/hooks.py`
- Reports and custom scripts

#### Development Workflow

1. **Copy apps to local:**
```bash
docker cp $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/. ./apps/
```

2. **Make changes locally** using your preferred code editor

3. **Copy modified files back to container:**
```bash
# Copy all changes back
docker cp ./apps/. $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/

# Or copy specific app changes
docker cp ./apps/erpnext/. $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/erpnext/
```

4. **Restart container to apply changes:**
```bash
docker compose -f pwd-with-apps.yml restart backend
```

#### Common Customization Examples

**Change Login Page Logo:**
```bash
# Copy custom logo
docker cp ./custom-logo.png $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/frappe/frappe/public/images/frappe-logo.svg
```

**Modify CSS Styling:**
```bash
# Edit CSS file locally
./apps/frappe/frappe/public/css/frappe-web.css

# Copy back changes
docker cp ./apps/frappe/frappe/public/css/frappe-web.css $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/frappe/frappe/public/css/
```

**Add Custom JavaScript:**
```bash
# Create custom JS file
echo "// Custom JavaScript" > ./apps/custom_app/custom_app/public/js/custom.js

# Copy to container
docker cp ./apps/custom_app/custom_app/public/js/custom.js $(docker ps -qf "name=backend"):/home/frappe/frappe-bench/apps/custom_app/custom_app/public/js/
```

#### Important Notes

- **Backup First**: Always backup original files before modifying
- **Container Restart**: Some changes require container restart to take effect
- **Database Changes**: Database schema changes need bench migrate command
- **Version Compatibility**: Ensure customizations work with Frappe version updates
- **Testing**: Test changes in development environment before production

#### Advanced Development

**Access Container Shell for Development:**
```bash
docker compose -f pwd-with-apps.yml exec backend bash
cd /home/frappe/frappe-bench
# Use bench commands for advanced operations
bench --site frontend migrate
bench --site frontend reinstall-app [app_name]
```

**Real-time File Sync (Advanced):**
```bash
# Install docker-sync for automatic file syncing
# This allows live editing without manual copy/paste
```

---

## AI Integration with Frappe Insights

### Natural Language Querying with Cost-Effective AI

This guide shows how to integrate AI for natural language querying in Frappe Insights with cost optimization and secure API key management.

### 1. Cost-Effective OpenAI Setup

#### Free Credits & Cost Optimization

**Get Started with Free Credits:**
1. **OpenAI Free Trial**: Sign up at https://platform.openai.com to get $5-18 in free credits
2. **Usage Monitoring**: Track usage to stay within free tier
3. **Model Selection**: Use cost-effective models

**Cost-Effective Model Choices:**
```python
# From most expensive to most affordable
MODEL_COSTS = {
    "gpt-4": "$0.03/1K tokens (input), $0.06/1K tokens (output)",
    "gpt-4-turbo": "$0.01/1K tokens (input), $0.03/1K tokens (output)", 
    "gpt-3.5-turbo": "$0.001/1K tokens (input), $0.002/1K tokens (output)"  # Most cost-effective
}
```

#### Secure API Key Configuration

**Method A: Environment Variables (Recommended)**
```yaml
# Add to pwd-with-apps.yml
services:
  backend:
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - OPENAI_MODEL=gpt-3.5-turbo  # Cost-effective default
```

**Method B: Frappe Site Config**
```python
# Access via Frappe configuration
import frappe

def get_openai_config():
    return {
        'api_key': frappe.conf.get('openai_api_key'),
        'model': frappe.conf.get('openai_model', 'gpt-3.5-turbo'),
        'max_tokens': int(frappe.conf.get('openai_max_tokens', 500))
    }
```

**Set Site Config Securely:**
```bash
# Access container
docker compose -f pwd-with-apps.yml exec backend bash

# Set in site config
cd /home/frappe/frappe-bench
bench --site frontend set-config -g openai_api_key "your-key-here"
bench --site frontend set-config -g openai_model "gpt-3.5-turbo"
bench --site frontend set-config -g openai_max_tokens "500"
```

### 2. Natural Language Query Implementation

#### Cost-Optimized Query Handler

```python
# custom_ai_app/custom_ai_app/api.py
import frappe
import openai
import json

class CostOptimizedAI:
    def __init__(self):
        self.config = self.get_secure_config()
        self.cache = {}
    
    def get_secure_config(self):
        """Get API key from secure configuration"""
        api_key = frappe.conf.get('openai_api_key') or os.environ.get('OPENAI_API_KEY')
        if not api_key:
            frappe.throw("OpenAI API key not configured")
        
        return {
            'api_key': api_key,
            'model': frappe.conf.get('openai_model', 'gpt-3.5-turbo'),
            'max_tokens': int(frappe.conf.get('openai_max_tokens', 500))
        }
    
    def natural_language_to_sql(self, question, schema_info):
        """Convert natural language to SQL with cost optimization"""
        cache_key = f"nl_sql:{hash(question + schema_info)}"
        
        # Check cache to avoid API calls
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        # Cost-optimized prompt
        prompt = f"""
        Convert this question to SQL for Frappe ERPNext:
        Question: {question}
        
        Available tables: {schema_info}
        
        Return only the SQL query without explanation.
        Use LIMIT 100 to reduce data transfer costs.
        """
        
        try:
            response = openai.ChatCompletion.create(
                model=self.config['model'],
                messages=[{"role": "user", "content": prompt}],
                max_tokens=self.config['max_tokens'],
                temperature=0  # Deterministic for SQL
            )
            
            sql_query = response.choices[0].message.content.strip()
            
            # Cache the result
            self.cache[cache_key] = sql_query
            
            # Log usage for cost tracking
            self.log_api_usage('nl_to_sql', response.usage)
            
            return sql_query
            
        except Exception as e:
            frappe.log_error(f"AI Query Failed: {str(e)}")
            return None
    
    def log_api_usage(self, operation, usage):
        """Track API usage for cost monitoring"""
        log_entry = frappe.get_doc({
            'doctype': 'AI Usage Log',
            'operation': operation,
            'model': self.config['model'],
            'prompt_tokens': usage.prompt_tokens,
            'completion_tokens': usage.completion_tokens,
            'total_tokens': usage.total_tokens,
            'estimated_cost': self.calculate_cost(usage),
            'timestamp': frappe.utils.now()
        })
        log_entry.insert(ignore_permissions=True)
    
    def calculate_cost(self, usage):
        """Calculate estimated cost in USD"""
        model = self.config['model']
        if model == 'gpt-3.5-turbo':
            return (usage.prompt_tokens * 0.001 + usage.completion_tokens * 0.002) / 1000
        elif model == 'gpt-4':
            return (usage.prompt_tokens * 0.03 + usage.completion_tokens * 0.06) / 1000
        return 0

@frappe.whitelist()
def query_with_natural_language(question):
    """API endpoint for natural language querying"""
    ai = CostOptimizedAI()
    
    # Get database schema (cached)
    schema = get_cached_schema()
    
    # Convert to SQL
    sql_query = ai.natural_language_to_sql(question, schema)
    
    if not sql_query:
        return {'error': 'Failed to generate query'}
    
    # Execute query safely
    try:
        result = frappe.db.sql(sql_query, as_dict=True)
        return {
            'query': sql_query,
            'data': result[:50],  # Limit results for cost savings
            'count': len(result)
        }
    except Exception as e:
        return {'error': f'Query execution failed: {str(e)}'}
```

### 3. Free Local Alternative: Ollama

#### Setup Ollama Container

**Add to pwd-with-apps.yml:**
```yaml
services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - frappe_network
    deploy:
      restart_policy:
        condition: on-failure

volumes:
  ollama_data:
```

#### Install Free Models

```bash
# Start Ollama container
docker compose -f pwd-with-apps.yml up -d ollama

# Install free models (in Ollama container)
docker compose -f pwd-with-apps.yml exec ollama ollama pull llama2
docker compose -f pwd-with-apps.yml exec ollama ollama pull codellama
docker compose -f pwd-with-apps.yml exec ollama ollama pull mistral
```

#### Ollama Integration (Free Alternative)

```python
# Free local AI using Ollama
import requests
import frappe

class OllamaAI:
    def __init__(self):
        self.base_url = "http://ollama:11434"
        self.model = frappe.conf.get('ollama_model', 'mistral')  # Free model
    
    def natural_language_to_sql(self, question, schema_info):
        """Convert natural language to SQL using free local model"""
        prompt = f"""
        Convert this question to SQL for Frappe ERPNext:
        Question: {question}
        Available tables: {schema_info}
        
        Return only the SQL query without explanation.
        """
        
        try:
            response = requests.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()['response'].strip()
            
        except Exception as e:
            frappe.log_error(f"Ollama Query Failed: {str(e)}")
        
        return None

@frappe.whitelist()
def query_with_local_ai(question):
    """API endpoint for local AI querying"""
    ai = OllamaAI()
    
    schema = get_cached_schema()
    sql_query = ai.natural_language_to_sql(question, schema)
    
    if not sql_query:
        return {'error': 'Failed to generate query'}
    
    try:
        result = frappe.db.sql(sql_query, as_dict=True)
        return {
            'query': sql_query,
            'data': result[:50],
            'count': len(result)
        }
    except Exception as e:
        return {'error': f'Query execution failed: {str(e)}'}
```

### 4. Hybrid Approach (Cost Optimization)

```python
class HybridAI:
    def __init__(self):
        self.ollama = OllamaAI()
        self.openai = CostOptimizedAI()
        self.use_free_first = frappe.conf.get('ai_use_free_first', True)
    
    def natural_language_to_sql(self, question, schema_info):
        """Try free local AI first, fallback to OpenAI if needed"""
        
        if self.use_free_first:
            # Try free local AI first
            result = self.ollama.natural_language_to_sql(question, schema_info)
            if result and self.validate_sql(result):
                return result
        
        # Fallback to OpenAI for better accuracy
        return self.openai.natural_language_to_sql(question, schema_info)
    
    def validate_sql(self, sql_query):
        """Basic SQL validation"""
        dangerous_keywords = ['DROP', 'DELETE', 'UPDATE', 'INSERT', 'ALTER']
        sql_upper = sql_query.upper()
        
        return not any(keyword in sql_upper for keyword in dangerous_keywords)
```

### 5. Frontend Integration

```javascript
// Add to Insights dashboard
class NaturalLanguageQuery {
    constructor() {
        this.setupUI();
    }
    
    setupUI() {
        const queryBox = `
            <div class="nl-query-container">
                <h4>🤖 Ask in Natural Language</h4>
                <input type="text" id="nl-question" placeholder="e.g., Show me top 10 customers by sales">
                <button onclick="executeNLQuery()">Generate Query</button>
                <div id="nl-results"></div>
            </div>
        `;
        
        document.querySelector('.dashboard-actions').insertAdjacentHTML('beforeend', queryBox);
    }
    
    async executeNLQuery() {
        const question = document.getElementById('nl-question').value;
        if (!question) return;
        
        try {
            const response = await frappe.call({
                method: 'custom_ai_app.api.query_with_natural_language',
                args: { question }
            });
            
            this.displayResults(response.message);
        } catch (error) {
            frappe.msgprint('Query failed: ' + error.message);
        }
    }
    
    displayResults(result) {
        const container = document.getElementById('nl-results');
        
        if (result.error) {
            container.innerHTML = `<div class="alert alert-danger">${result.error}</div>`;
            return;
        }
        
        container.innerHTML = `
            <div class="nl-query-result">
                <h5>Generated SQL:</h5>
                <code>${result.query}</code>
                <h5>Results (${result.count} rows):</h5>
                <div class="table-responsive">
                    ${this.format_table(result.data)}
                </div>
            </div>
        `;
    }
}

// Initialize when dashboard loads
$(document).ready(() => {
    new NaturalLanguageQuery();
});
```

### 6. Setup Instructions

#### Step 1: Configure API Keys
```bash
# Option A: Environment variables
export OPENAI_API_KEY="your-key-here"

# Option B: Site config
docker compose -f pwd-with-apps.yml exec backend bash
bench --site frontend set-config -g openai_api_key "your-key-here"
```

#### Step 2: Create Custom AI App
```bash
docker compose -f pwd-with-apps.yml exec backend bash
cd /home/frappe/frappe-bench
bench new-app custom_ai_app
bench --site frontend install-app custom_ai_app
```

#### Step 3: Add to apps.json
```json
{
  "url": "https://github.com/frappe/insights",
  "branch": "version-15"
},
{
  "url": "./custom_ai_app",
  "branch": "main"
}
```

#### Step 4: Restart Services
```bash
docker compose -f pwd-with-apps.yml down
./setup.sh
docker compose -f pwd-with-apps.yml up -d
```

### 7. Cost Monitoring Dashboard

```python
@frappe.whitelist()
def get_ai_usage_stats():
    """Get AI usage statistics for cost monitoring"""
    data = frappe.db.sql("""
        SELECT 
            DATE(timestamp) as date,
            SUM(total_tokens) as tokens,
            SUM(estimated_cost) as cost,
            COUNT(*) as calls
        FROM `tabAI Usage Log`
        WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY DATE(timestamp)
        ORDER BY date DESC
    """, as_dict=True)
    
    return {
        'data': data,
        'total_cost': sum(row.cost for row in data),
        'total_tokens': sum(row.tokens for row in data)
    }
```

### Important Notes

- **Free Credits**: OpenAI provides $5-18 free credits for new accounts
- **Local Models**: Ollama models are completely free but require more RAM
- **Cost Tracking**: Monitor usage to avoid unexpected charges
- **Security**: Never commit API keys to version control
- **Rate Limits**: Implement caching to reduce API calls
- **Model Selection**: Use gpt-3.5-turbo for cost-effective operations

---

## AI Integration with Frappe Insights

### Natural Language Querying with AI

This guide shows how to integrate AI models with Frappe Insights to enable natural language querying capabilities.

### Choose Your AI Approach

#### Option A: Cost-Effective Hybrid (Recommended)
- Use **Ollama** (free local AI) for most queries
- Use **OpenAI** only when higher accuracy is needed

#### Option B: OpenAI Only
- Simpler setup but involves costs
- Better accuracy for complex queries

### Step 1: Setup Ollama (Free Local AI)

Add Ollama service to your `docker-setup/pwd-with-apps.yml`:

```yaml
services:
  # ... existing services ...
  
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    networks:
      - frappe_network
    deploy:
      restart_policy:
        condition: on-failure

volumes:
  # ... existing volumes ...
  ollama_data:
```

Install free AI models:

```bash
# Start containers
docker compose -f docker-setup/pwd-with-apps.yml up -d

# Install free models
docker compose -f docker-setup/pwd-with-apps.yml exec ollama ollama pull mistral
docker compose -f docker-setup/pwd-with-apps.yml exec ollama ollama pull codellama
```

### Step 2: Configure OpenAI (Optional)

Get your API key from https://platform.openai.com and configure it securely:

```bash
# Access backend container
docker compose -f docker-setup/pwd-with-apps.yml exec backend bash

# Securely set OpenAI API key
bench --site frontend set-config -g openai_api_key "your-api-key-here"
bench --site frontend set-config -g openai_model "gpt-3.5-turbo"
bench --site frontend set-config -g openai_max_tokens "500"
```

### Step 3: Create Custom AI App

```bash
# Access container and create custom app
docker compose -f docker-setup/pwd-with-apps.yml exec backend bash
cd /home/frappe/frappe-bench
bench new-app insights_ai

# Install the app
bench --site frontend install-app insights_ai
```

### Step 4: AI Integration Code

Create the AI integration files in your new app:

**AI Configuration (`insights_ai/insights_ai/ai_config.py`):**
```python
import frappe
import os

class AIConfig:
    @staticmethod
    def get_openai_config():
        """Get OpenAI configuration"""
        api_key = frappe.conf.get('openai_api_key')
        if not api_key:
            return None
        return {
            'api_key': api_key,
            'model': frappe.conf.get('openai_model', 'gpt-3.5-turbo'),
            'max_tokens': int(frappe.conf.get('openai_max_tokens', 500))
        }
    
    @staticmethod
    def get_ollama_config():
        """Get Ollama configuration"""
        return {
            'base_url': 'http://ollama:11434',
            'model': 'mistral',
            'timeout': 30
        }
```

**Natural Language API (`insights_ai/insights_ai/api.py`):**
```python
import frappe
import requests
from .ai_config import AIConfig

@frappe.whitelist()
def natural_language_to_sql(question):
    """Convert natural language to SQL using AI"""
    
    # Try Ollama first (free)
    ollama_result = query_ollama(question)
    if ollama_result:
        return {'sql': ollama_result, 'source': 'Ollama (Free)'}
    
    # Fallback to OpenAI if available
    openai_result = query_openai(question)
    if openai_result:
        return {'sql': openai_result, 'source': 'OpenAI'}
    
    return {'error': 'AI services unavailable'}

def query_ollama(question):
    """Query Ollama for SQL generation"""
    try:
        config = AIConfig.get_ollama_config()
        
        prompt = f"""
        Convert this question to SQL for Frappe ERPNext:
        Question: {question}
        
        Available tables: Sales Invoice, Purchase Order, Customer, Supplier, Item
        Return only the SQL query without explanation.
        """
        
        response = requests.post(
            f"{config['base_url']}/api/generate",
            json={
                "model": config['model'],
                "prompt": prompt,
                "stream": False
            },
            timeout=config['timeout']
        )
        
        if response.status_code == 200:
            return response.json()['response'].strip()
            
    except Exception as e:
        frappe.log_error(f"Ollama query failed: {str(e)}")
    
    return None

def query_openai(question):
    """Query OpenAI for SQL generation"""
    try:
        config = AIConfig.get_openai_config()
        if not config:
            return None
            
        import openai
        client = openai.OpenAI(api_key=config['api_key'])
        
        response = client.chat.completions.create(
            model=config['model'],
            messages=[{
                "role": "user",
                "content": f"""
                Convert this question to SQL for Frappe ERPNext:
                Question: {question}
                
                Available tables: Sales Invoice, Purchase Order, Customer, Supplier, Item
                Return only the SQL query without explanation.
                """
            }],
            max_tokens=config['max_tokens'],
            temperature=0
        )
        
        return response.choices[0].message.content.strip()
        
    except Exception as e:
        frappe.log_error(f"OpenAI query failed: {str(e)}")
    
    return None

@frappe.whitelist()
def execute_ai_query(question):
    """Execute AI-generated query and return results"""
    # Convert to SQL
    sql_result = natural_language_to_sql(question)
    
    if 'error' in sql_result:
        return sql_result
    
    # Execute query safely
    try:
        # Basic SQL validation
        sql = sql_result['sql']
        dangerous_keywords = ['DROP', 'DELETE', 'UPDATE', 'INSERT', 'ALTER']
        
        if any(keyword.upper() in sql.upper() for keyword in dangerous_keywords):
            return {'error': 'Unsafe query detected'}
        
        # Execute query
        data = frappe.db.sql(sql, as_dict=True)
        
        return {
            'sql': sql,
            'data': data[:100],  # Limit results
            'count': len(data),
            'source': sql_result['source']
        }
        
    except Exception as e:
        return {'error': f'Query execution failed: {str(e)}'}
```

### Step 5: Frontend Integration

Add JavaScript to your Insights dashboard:

```javascript
// Add to Insights dashboard
class AINaturalLanguageQuery {
    constructor() {
        this.setupUI();
    }
    
    setupUI() {
        const queryBox = `
            <div class="nl-query-container" style="margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
                <h4>🤖 Ask in Natural Language</h4>
                <div class="form-group">
                    <input type="text" id="nl-question" class="form-control" 
                           placeholder="e.g., Show me top 10 customers by sales">
                </div>
                <button class="btn btn-primary" onclick="executeAIQuery()">Generate & Execute Query</button>
                <div id="ai-results" style="margin-top: 15px;"></div>
            </div>
        `;
        
        // Add to dashboard
        $('.dashboard-content').prepend(queryBox);
    }
}

// Initialize when page loads
$(document).ready(() => {
    new AINaturalLanguageQuery();
});

function executeAIQuery() {
    const question = document.getElementById('nl-question').value;
    if (!question) {
        frappe.msgprint('Please enter a question');
        return;
    }
    
    // Show loading
    document.getElementById('ai-results').innerHTML = '<div class="alert alert-info">Processing your query...</div>';
    
    frappe.call({
        method: 'insights_ai.api.execute_ai_query',
        args: { question },
        callback: function(r) {
            displayResults(r.message);
        }
    });
}

function displayResults(result) {
    const container = document.getElementById('ai-results');
    
    if (result.error) {
        container.innerHTML = `<div class="alert alert-danger">${result.error}</div>`;
        return;
    }
    
    let html = `
        <div class="ai-query-result">
            <h5>Generated SQL (${result.source}):</h5>
            <pre style="background: #f5f5f5; padding: 10px; border-radius: 4px;">${result.sql}</pre>
            <h5>Results (${result.count} rows):</h5>
    `;
    
    if (result.data && result.data.length > 0) {
        html += '<div class="table-responsive"><table class="table table-bordered">';
        
        // Headers
        const headers = Object.keys(result.data[0]);
        html += '<thead><tr>';
        headers.forEach(header => {
            html += `<th>${header}</th>`;
        });
        html += '</tr></thead><tbody>';
        
        // Data rows
        result.data.slice(0, 20).forEach(row => {
            html += '<tr>';
            headers.forEach(header => {
                html += `<td>${row[header] || ''}</td>`;
            });
            html += '</tr>';
        });
        
        html += '</tbody></table></div>';
        
        if (result.count > 20) {
            html += `<p class="text-muted">Showing first 20 of ${result.count} results</p>`;
        }
    } else {
        html += '<p>No results found</p>';
    }
    
    html += '</div>';
    container.innerHTML = html;
}
```

### Step 6: Update App Configuration

Add your AI app to `apps.json`:

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
      "url": "./insights_ai",
      "branch": "main"
    }
  ]
}
```

### Step 7: Restart and Test

```bash
# Restart services
docker compose -f docker-setup/pwd-with-apps.yml down
./setup.sh
docker compose -f docker-setup/pwd-with-apps.yml up -d
```

### Usage Examples

Try these natural language queries:
- "Show me top 10 customers by sales"
- "What are my total sales this month?"
- "List all pending purchase orders"
- "Show me items with low stock"

### Important Notes

- **Cost Management**: Ollama is free, OpenAI costs per token
- **Security**: SQL validation prevents dangerous queries
- **Performance**: Results are limited to 100 rows for efficiency
- **Fallback**: System tries Ollama first, then OpenAI

---

## Mobile Support

### Frappe HR Mobile Version

Frappe HR includes a fully responsive mobile interface that works seamlessly on smartphones and tablets. When accessing the HR module from mobile devices, users get an optimized experience with:

#### Mobile Features

**Check-In/Check-Out**
- One-touch attendance marking
- GPS-enabled location tracking (if configured)
- Real-time attendance status

**Quick Actions**
- Request attendance with single tap
- Request shift changes
- Apply for leave with mobile-optimized forms

**Navigation**
- Bottom navigation bar for easy thumb access
- Home, Attendance, Leaves, Expenses, and Salary sections
- Swipe gestures for enhanced usability

**Responsive Design**
- Automatic layout adjustment for screen size
- Touch-friendly buttons and forms
- Progressive Web App (PWA) support for app-like experience

#### Mobile Access

1. **URL**: http://xxx.xxx.xx.xxx:8080/hrms/home (replace with your IP)
2. **Browser**: Any modern mobile browser (Chrome, Safari, Firefox)
3. **Login**: Same credentials as desktop (Administrator/admin or employee accounts)

#### Mobile App Features

- **Home Dashboard**: Quick overview of attendance, leaves, and notifications
- **Attendance Management**: Check-in/out, view attendance history
- **Leave Requests**: Apply for leave, check leave balance, view status
- **Expense Claims**: Submit expenses, upload receipts, track approvals
- **Salary Slips**: View payslips and salary breakdown

#### Benefits

- **No Separate App Needed**: Works directly in mobile browser
- **Offline Capability**: Basic functions work without internet (PWA)
- **Push Notifications**: Receive alerts for leave approvals, attendance reminders
- **Cross-Platform**: Works on iOS, Android, and tablet devices

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
./setup.sh --no-cache
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