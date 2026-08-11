# Install External MariaDB on Ubuntu

This guide installs MariaDB on a separate Ubuntu VM and prepares it for this
Frappe Docker setup. This project currently tests with MariaDB `10.6`, so use
MariaDB instead of Oracle MySQL.

For an existing site, database installation is only the first step. Follow
[Existing Site Migration](external-database.md#existing-site-migration) before
changing Frappe's database host.

## Required Values

Replace these placeholders in the commands:

```text
<APP_PRIVATE_IP>   Private IP of the Frappe server
<DB_PRIVATE_IP>    Private IP of the database VM
<ADMIN_PRIVATE_IP> Private IP of the administrator or VPN
```

Example:

```text
Frappe server: 10.10.0.10
Database VM:   10.10.0.20
```

Use private IP addresses. Never expose database port `3306` to the public
internet.

### If You Have More Than One Frappe Server

`<APP_PRIVATE_IP>` means the private IP of a Frappe server. If there is only
one Frappe server, use its one private IP:

```text
Frappe server: 10.10.0.10
Database VM:   10.10.0.20
```

If there are multiple Frappe servers, record every private IP:

```text
Frappe App 1: 10.10.0.11
Frappe App 2: 10.10.0.12
Frappe App 3: 10.10.0.13
Database VM:  10.10.0.20
```

Add one database firewall rule for each Frappe server:

```bash
sudo ufw allow from 10.10.0.11 to any port 3306 proto tcp
sudo ufw allow from 10.10.0.12 to any port 3306 proto tcp
sudo ufw allow from 10.10.0.13 to any port 3306 proto tcp
```

Do not use `0.0.0.0/0` to make multiple-server setup easier. The load balancer
does not connect to MariaDB; each Frappe server connects directly to MariaDB.

The temporary `frappe_provisioner` account is needed only for the Frappe server
that runs `setup.sh`. Other Frappe servers use the site's normal database
username and password. All Frappe servers for the same site must use the same
site database credentials.

## Step 1: Update Ubuntu

Connect to the database VM:

```bash
ssh <UBUNTU_USER>@<DB_PRIVATE_IP>
```

Update Ubuntu and install the required tools:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl ufw
```

## Step 2: Install MariaDB 10.6

Configure MariaDB's official 10.6 package repository:

```bash
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup \
  -o /tmp/mariadb_repo_setup

sudo bash /tmp/mariadb_repo_setup \
  --mariadb-server-version=mariadb-10.6
```

Install MariaDB:

```bash
sudo apt update
sudo apt install -y mariadb-server mariadb-client
sudo systemctl enable --now mariadb
```

Verify it:

```bash
mariadb --version
sudo systemctl status mariadb --no-pager
sudo mariadb-admin ping
```

Expected health result:

```text
mysqld is alive
```

## Step 3: Configure MariaDB for Frappe

Create a configuration file:

```bash
sudo nano /etc/mysql/mariadb.conf.d/60-frappe.cnf
```

Add this configuration and replace `<DB_PRIVATE_IP>`:

```ini
[mariadb]
bind-address = <DB_PRIVATE_IP>
port = 3306

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake

innodb-file-per-table = 1
innodb-read-only-compressed = OFF
max-allowed-packet = 256M
```

Restart and check MariaDB:

```bash
sudo systemctl restart mariadb
sudo systemctl status mariadb --no-pager
sudo ss -lntp | grep ':3306'
```

The listener should show `<DB_PRIVATE_IP>:3306`, not `0.0.0.0:3306`.

## Step 4: Secure MariaDB

Run the security setup:

```bash
sudo mariadb-secure-installation
```

Recommended choices:

```text
Remove anonymous users: Y
Disallow root login remotely: Y
Remove test database: Y
Reload privilege tables: Y
```

Keep root administration local to the database VM:

```bash
sudo mariadb
```

Type `exit` to leave the MariaDB console.

## Step 5: Configure the Firewall

Allow SSH from the administrator address first:

```bash
sudo ufw allow from <ADMIN_PRIVATE_IP> to any port 22 proto tcp
```

Allow MariaDB only from the Frappe server:

```bash
sudo ufw allow from <APP_PRIVATE_IP> to any port 3306 proto tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw status numbered
```

Add the same rule to the VM provider's firewall or security group:

```text
Protocol: TCP
Port:     3306
Source:   <APP_PRIVATE_IP>/32
```

Never use `0.0.0.0/0` as the source.

## Step 6: Create the Frappe Provisioning User

Open MariaDB:

```bash
sudo mariadb
```

Replace the private IP and password, then run:

```sql
CREATE USER 'frappe_provisioner'@'<APP_PRIVATE_IP>'
  IDENTIFIED BY '<STRONG_PROVISIONING_PASSWORD>';

GRANT ALL PRIVILEGES ON *.*
  TO 'frappe_provisioner'@'<APP_PRIVATE_IP>' WITH GRANT OPTION;

FLUSH PRIVILEGES;
EXIT;
```

This account is powerful because Frappe uses it to create a new site database
and its runtime database user. It is restricted to the Frappe server's private
IP. Remove it after a fresh site has been created and verified.

## Step 7: Test From the Frappe Server

On the Frappe server:

```bash
nc -vz <DB_PRIVATE_IP> 3306
```

Expected result:

```text
Connection to <DB_PRIVATE_IP> 3306 port [tcp/mysql] succeeded!
```

If `nc` is unavailable, install it with:

```bash
sudo apt install -y netcat-openbsd
```

## Connect Frappe

On the Frappe server, update `docker-setup/.env`:

```env
DATABASE_MODE=external
DB_HOST=<DB_PRIVATE_IP>
DB_PORT=3306
DB_ROOT_USERNAME=frappe_provisioner
DB_ROOT_PASSWORD=<STRONG_PROVISIONING_PASSWORD>
DB_NAME=
DB_PASSWORD=<STRONG_SITE_DATABASE_PASSWORD>
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false
```

Do not use `localhost` or `127.0.0.1` for `DB_HOST`. Then create a fresh site:

```bash
cd ~/my-frappe-setup/docker-setup
./setup.sh
```

Check the displayed external database address before typing `SETUP`.

For an existing site, do not run setup as a migration shortcut. Continue with
[External MariaDB](external-database.md#existing-site-migration).

## Remove the Provisioning User

After a fresh site works correctly, run on the database VM:

```bash
sudo mariadb
```

```sql
DROP USER 'frappe_provisioner'@'<APP_PRIVATE_IP>';
FLUSH PRIVILEGES;
EXIT;
```

Remove the temporary credentials from Frappe's `.env`:

```env
DB_ROOT_USERNAME=
DB_ROOT_PASSWORD=
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false
```

Keep `DATABASE_MODE=external`, `DB_HOST`, and `DB_PORT` unchanged.
