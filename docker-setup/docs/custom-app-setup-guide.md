# Custom App Development Guide (Frappe Docker)

This guide explains how to create, develop, and manage custom Frappe apps (like `mdea_custom`) within this Docker-based development environment.

---

## 1. Creating a New Custom App

To create a new app from scratch while the containers are running:

1. **Enter the Backend Container**:
   ```bash
   cd docker-setup
   docker compose exec backend bash
   ```

2. **Generate App Boilerplate**:
   ```bash
   bench new-app <app_name>
   ```
   *Example: `bench new-app mdea_custom`*
   Provide the requested details (Title, Description, Publisher, etc.).

3. **Sync to Host (One-Time Step)**:
   If the app remains only inside the container, copy it out to your host:
   ```bash
   # From host, create the folder first
   mkdir -p ../apps/mdea_custom
   
   # Copy code from container to host
   docker cp docker-setup-backend-1:/home/frappe/frappe-bench/apps/mdea_custom/. ../apps/mdea_custom/
   ```

---

## 2. Managing Version Control (Git)

Each custom app should be its own Git repository.

1. **Initialize Git in the App folder**:
   ```bash
   cd ../apps/mdea_custom
   git init
   git remote add origin https://github.com/HtetNyiAung/mdea_custom.git
   ```

2. **Commit and Push**:
   ```bash
   git add .
   git commit -m "chore: initialize mdea_custom app structure"
   git branch -M main
   git push -f origin main
   ```

---

## 3. Integrating the App into the Setup

### Step 1: Update `apps.json`
Add your app to the `docker-setup/apps.json` file. Ensure the `url` is provided so the Docker build can find it:
```json
{
  "name": "mdea_custom",
  "url": "https://github.com/HtetNyiAung/mdea_custom.git",
  "branch": "main"
}
```

### Step 2: Configure Volume Mounting
Ensure the app is mounted in `docker-setup/pwd-with-apps.yml` for **Immediate Reflection** (Hot-Reloading):
```yaml
services:
  backend:
    volumes:
      - ../apps/mdea_custom:/home/frappe/frappe-bench/apps/mdea_custom
```

---

## 4. Development Workflow

### Hot Reloading
Because we use **Volume Mounts**, your changes to Python/JS files on the host are instantly reflected inside the container. You don't need to rebuild the image during development.

### Running Migrations
If you create a new DocType or change fields, run migrations:
```bash
docker compose exec backend bench --site frontend migrate
```

---

## 5. Summary of `setup.sh`

Your `./setup.sh` is now automated to:
1. Update git submodules.
2. Build the Docker image with all apps from `apps.json`.
3. Install/Update the app on the site.
4. Run `bench migrate`.

---

## 6. Troubleshooting

- **403 Not Permitted on Login**: Remember, Server Scripts don't work with OAuth login. Use the custom app's `hooks.py` for role assignment logic.
- **Permission Errors**: If files are owned by root, run: `sudo chown -R $USER:$USER ../apps/mdea_custom`.
