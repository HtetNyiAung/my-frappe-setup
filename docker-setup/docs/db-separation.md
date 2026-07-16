# Database Separation Guide

This guide explains how to separate the MariaDB database from the main application server in the `my-frappe-setup` environment. By running the database on a separate server, you reduce RAM/CPU usage on the application server and allow for better scalability.

---

## 1. Remote Database Server Configuration

Before configuring the App Server, you must set up your remote MariaDB server to allow secure external connections.

### A. Configure MariaDB Configuration File
Edit the MariaDB configuration file (typically `/etc/mysql/mariadb.conf.d/50-server.cnf` or `/etc/mysql/my.cnf`):

1. **Allow remote connections**:
   Change `bind-address` to listen on all interfaces or specific network interfaces:
   ```ini
   bind-address = 0.0.0.0
   ```

2. **Ensure Frappe compatibility settings**:
   Ensure character set and collation are configured correctly:
   ```ini
   [mysqld]
   character-set-server = utf8mb4
   collation-server = utf8mb4_unicode_ci
   skip-character-set-client-handshake
   ```

3. **Restart MariaDB**:
   ```bash
   sudo systemctl restart mariadb
   ```

### B. Grant Access Permissions
Login to the remote MariaDB shell and grant permissions to the App Server IP address:

```sql
-- Replace 'APP_SERVER_IP' with the actual IP address of your application server
-- Replace 'YOUR_REMOTE_ROOT_PASSWORD' with your secure database root password
CREATE USER 'root'@'APP_SERVER_IP' IDENTIFIED BY 'YOUR_REMOTE_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'APP_SERVER_IP' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

---

## 2. App Server Configuration

### A. Environment Configuration (`.env`)
Update the following parameters in your `.env` file on the App Server:

```env
DB_HOST=<remote-db-server-ip>   # Remote Database Server IP/Hostname
DB_PORT=3306                    # Database Port (usually 3306)
DB_ROOT_USERNAME=root           # Remote Database root username
MYSQL_ROOT_PASSWORD=your_pass   # Remote Database root password
MARIADB_ROOT_PASSWORD=your_pass # Remote Database root password
```

### B. Docker Compose Configurations
In `pwd-with-apps.yml`, the local `db` service definition and `db-data` volume have been removed. Services now rely on the external DB host and port using the `${DB_HOST}` and `${DB_PORT}` environment variables.

To apply changes, run:
```bash
./setup.sh
```

---

## 3. Local Testing

To test the database separation configuration locally on your development machine:

### Method: Standalone Docker DB Container
You can simulate a remote database by spinning up a separate MariaDB container on the same Docker network.

1. **Run a temporary MariaDB container**:
   ```bash
   docker run -d --name temp-mariadb \
     -p 3306:3306 \
     -e MARIADB_ROOT_PASSWORD=admin \
     mariadb:10.6 \
     --character-set-server=utf8mb4 \
     --collation-server=utf8mb4_unicode_ci
   ```

2. **Connect it to the setup network**:
   ```bash
   docker network connect docker-setup_frappe_network temp-mariadb
   ```

3. **Configure `.env`**:
   ```env
   DB_HOST=temp-mariadb
   DB_PORT=3306
   MYSQL_ROOT_PASSWORD=admin
   ```

4. **Run Setup**:
   ```bash
   ./setup.sh
   ```
   This will boot the app server, bypass the local `db` container, and create/migrate the site on the `temp-mariadb` container.
