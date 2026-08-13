# External MariaDB on Ubuntu for Frappe Docker

This guide installs MariaDB on a separate Ubuntu server and connects the
Frappe Docker stack to it over a private network. It covers both:

1. a **fresh site**, created directly on the external database; and
2. an **existing site**, moved from the bundled MariaDB container to the
   external database.

Read Step 0 before changing `.env`. The two paths use `DB_NAME` and
`DB_PASSWORD` differently.

This repository targets Frappe Framework `version-16`. Its current documented
database requirement is MariaDB `11.8`. Recheck the requirement for the exact
Frappe branch before installing or upgrading MariaDB:
[Frappe installation requirements](https://docs.frappe.io/framework/user/en/installation).

## Important Configuration Rule

Frappe database configuration is split between two places:

| Configuration | File | Meaning |
|---|---|---|
| Database server address | `docker-setup/.env` | `DATABASE_MODE`, `DB_HOST`, and `DB_PORT` |
| Existing site's database login | `sites/<SITE_DOMAIN>/site_config.json` | `db_name`, `db_user`, and `db_password` |
| Fresh-site creation values | `docker-setup/.env` | `DB_NAME` and `DB_PASSWORD`, passed to `bench new-site` |

`DB_NAME` and `DB_PASSWORD` in `.env` are used only when `setup.sh` creates a
new site. They do not override an existing site's `site_config.json`.

For example, if an existing site contains:

```json
{
  "db_name": "_example_site_database",
  "db_user": "_example_site_database",
  "db_password": "<SITE_DATABASE_PASSWORD>"
}
```

setting `DB_NAME=dpuat` in `.env` does not switch that existing site to
`dpuat`. Use one of the existing-site migration options in Step 11.

Never commit real IP addresses, passwords, encryption keys, or customer data
to this repository. Replace every angle-bracket placeholder before running a
command.

## Step 0: Choose the Correct Path

| Situation | Path |
|---|---|
| No Frappe site exists yet | Complete Steps 1–10, then Steps 12–14 |
| A site currently uses the bundled `db` container | Complete Steps 1–6 and 9, then Steps 11–14 |
| The external server already contains an imported site database | Complete Steps 1–6 and 9, then Steps 11.4–14 |

Do not run the fresh-site path against an imported production database.
Changing `DB_HOST` changes the destination; it does not copy data.

## Step 1: Record the Network Values

Use these placeholders throughout this guide:

```text
<APP_PRIVATE_IP>    Source IP used by the App Server to reach MariaDB
<DB_PRIVATE_IP>     Private IP of the Database Server
<ADMIN_PRIVATE_IP>  Source IP allowed to SSH to the Database Server
<SITE_DOMAIN>       Frappe site directory name, for example frontend
```

### 1.1 Find the Database Server IP

Run on the **Database Server**:

```bash
ip -br address
```

Record the private address on the active interface as `<DB_PRIVATE_IP>`.

### 1.2 Find the App Server's routed source IP

Run on the **App Server**:

```bash
ip route get <DB_PRIVATE_IP>
hostname -I
```

Example:

```text
192.168.89.250 via 192.168.99.1 dev ens18 src 192.168.99.122
```

The address after `src` is `<APP_PRIVATE_IP>`. Use that exact address in the
UFW and MariaDB account rules. Do not guess it from a Docker bridge address.

### 1.3 Find the SSH administrator source IP

Run inside the current SSH session on the **Database Server**:

```bash
printf '%s\n' "$SSH_CONNECTION"
```

The first address is normally the administrator's source address. Confirm it
before changing firewall rules and record it as `<ADMIN_PRIVATE_IP>`.

## Step 2: Install MariaDB on the Database Server

Connect to the Database Server and install prerequisites:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl ufw netcat-openbsd tcpdump
```

If Ubuntu reports that a reboot is required, reboot and reconnect before
continuing.

Install the MariaDB `11.8` repository:

```bash
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup \
  -o /tmp/mariadb_repo_setup

sudo bash /tmp/mariadb_repo_setup \
  --mariadb-server-version=mariadb-11.8
```

Confirm the candidate version before installation:

```bash
apt-cache policy mariadb-server
```

The candidate must be the intended MariaDB `11.8` release. Then install and
start it:

```bash
sudo apt update
sudo apt install -y mariadb-server mariadb-client
sudo systemctl enable --now mariadb
```

Verify it:

```bash
mariadb --version
sudo systemctl status mariadb --no-pager -l
sudo mariadb-admin ping
```

Required result:

```text
mysqld is alive
```

Do not perform an unplanned in-place MariaDB major-version change on a server
that already contains data. Back up and test the supported upgrade path first.

## Step 3: Configure MariaDB for Frappe

Create a dedicated configuration file on the **Database Server**:

```bash
sudo nano /etc/mysql/mariadb.conf.d/60-frappe.cnf
```

Add the following, replacing `<DB_PRIVATE_IP>`:

```ini
[mariadb]
bind-address = <DB_PRIVATE_IP>
port = 3306

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake

innodb-file-per-table = 1
max-allowed-packet = 256M
```

Restart MariaDB and verify the listener:

```bash
sudo systemctl restart mariadb
sudo systemctl status mariadb --no-pager -l
sudo ss -lntp | grep ':3306'
```

Required listener:

```text
LISTEN ... <DB_PRIVATE_IP>:3306 ... mariadbd
```

Do not expose MariaDB on a public interface. Binding to the private address and
restricting the firewall are separate protections; both are required.

## Step 4: Secure the MariaDB Installation

Run:

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

Confirm that local administrative access still works:

```bash
sudo mariadb
```

Then exit:

```sql
EXIT;
```

Frappe does not require remote MariaDB `root` login. A temporary, host-limited
provisioning account is used for a fresh site.

## Step 5: Configure Firewalls

Keep the current SSH session open while changing firewall rules.

### 5.1 Allow SSH from the administrator

On the **Database Server**:

```bash
sudo ufw allow from <ADMIN_PRIVATE_IP> to <DB_PRIVATE_IP> port 22 proto tcp
```

Open a second SSH connection and confirm it works before removing any older SSH
rule.

### 5.2 Allow MariaDB only from the App Server

```bash
sudo ufw allow from <APP_PRIVATE_IP> to <DB_PRIVATE_IP> port 3306 proto tcp
```

Add one exact rule for each App Server if there are multiple application
servers. A load balancer normally does not need MariaDB access.

### 5.3 Enable the firewall policy

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw reload
sudo ufw status numbered
```

The database rule should have this shape:

```text
<DB_PRIVATE_IP> 3306/tcp  ALLOW IN  <APP_PRIVATE_IP>
```

Also add the same narrow rule to any Proxmox firewall, VLAN ACL, router ACL, or
cloud security group:

```text
Source:      <APP_PRIVATE_IP>/32
Destination: <DB_PRIVATE_IP>
Protocol:    TCP
Port:        3306
Action:      Allow
```

Never allow MariaDB from `0.0.0.0/0`.

## Step 6: Test the TCP Path

Run locally on the **Database Server**:

```bash
nc -vz -w 5 <DB_PRIVATE_IP> 3306
```

Run on the **App Server**:

```bash
ip route get <DB_PRIVATE_IP>
nc -vz -w 5 <DB_PRIVATE_IP> 3306
```

Required result:

```text
Connection to <DB_PRIVATE_IP> 3306 port [tcp/mysql] succeeded!
```

This proves only that TCP routing, MariaDB listening, and firewalls work. It
does not prove that a MariaDB username, password, database, or grant is valid.

### Troubleshooting a failed port test

| Result | Likely cause | Check |
|---|---|---|
| `Connection refused` | MariaDB is not listening on the target | `systemctl status mariadb` and `ss -lntp` |
| `timed out` | A host or upstream firewall drops traffic | Routed source IP, UFW, VLAN, and provider rules |
| `No route to host` | Routing or subnet configuration is missing | Gateway, route table, and VLAN configuration |

For a timeout, run on the Database Server:

```bash
sudo tcpdump -ni any 'tcp port 3306'
```

Repeat `nc` from the App Server:

- no packet arrives: an upstream route or firewall is blocking it;
- a SYN arrives from a different source: use that verified source in the rule;
- a SYN arrives but there is no SYN-ACK: inspect UFW/nftables locally;
- both directions appear: inspect the return route and App Server firewall.

## Step 7: Create a Temporary Provisioning Account

This account is required for a **fresh site** because `bench new-site` must
create the site database and runtime user. An existing-site migration that
creates its database and runtime user manually may skip this step.

Open MariaDB on the **Database Server**:

```bash
sudo mariadb
```

Create a strong, temporary account restricted to `<APP_PRIVATE_IP>`:

```sql
CREATE USER 'frappe_provisioner'@'<APP_PRIVATE_IP>'
  IDENTIFIED BY '<STRONG_PROVISIONER_PASSWORD>';

GRANT ALL PRIVILEGES ON *.*
  TO 'frappe_provisioner'@'<APP_PRIVATE_IP>' WITH GRANT OPTION;

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'frappe_provisioner'@'<APP_PRIVATE_IP>';
EXIT;
```

Do not use a MySQL Workbench account as `DB_ROOT_USERNAME`. The provisioning
account is powerful and must be removed after fresh-site creation.

## Step 8: Test MariaDB Authentication

Install a MariaDB client on the **App Server** if required:

```bash
sudo apt update
sudo apt install -y mariadb-client
```

For the fresh-site path, test the temporary provisioner:

```bash
mariadb --protocol=TCP \
  --host=<DB_PRIVATE_IP> \
  --port=3306 \
  --user=frappe_provisioner \
  --password \
  --execute="SELECT VERSION(), USER(), CURRENT_USER();"
```

Enter the password only at the prompt. `CURRENT_USER()` must show the account
with the expected App Server host restriction.

An `Access denied` result means the username, password, or MariaDB `Host` value
does not match. Do not change the host to `%` as a shortcut.

## Step 9: Back Up the App Server Configuration

Before either setup path, back up the Frappe site configuration and record the
current Compose state.

Run on the **App Server**:

```bash
cd ~/my-frappe-setup/docker-setup
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml ps
```

If `<SITE_DOMAIN>` already exists, back up its configuration inside the shared
sites volume:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend cp \
  sites/<SITE_DOMAIN>/site_config.json \
  sites/<SITE_DOMAIN>/site_config.json.before-external-db
```

Display it with secrets redacted:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend jq \
  'if .db_password then .db_password="<redacted>" else . end
   | if .encryption_key then .encryption_key="<redacted>" else . end
   | if .s3_secret_key then .s3_secret_key="<redacted>" else . end' \
  sites/<SITE_DOMAIN>/site_config.json
```

Never replace or regenerate an existing site's `encryption_key`. It is needed
to decrypt credentials already stored by Frappe.

## Step 10: Fresh Site Setup

Use this path only when `<SITE_DOMAIN>` does not already exist and no existing
database is being imported.

### 10.1 Configure `.env`

Edit `docker-setup/.env` on the **App Server**:

```env
DATABASE_MODE=external
DB_HOST=<DB_PRIVATE_IP>
DB_PORT=3306

# Keep valid values for local mode/rollback. They are not external credentials.
MYSQL_ROOT_PASSWORD=<LOCAL_COMPOSE_DB_ROOT_PASSWORD>
MARIADB_ROOT_PASSWORD=<LOCAL_COMPOSE_DB_ROOT_PASSWORD>

# Temporary external provisioning account used by bench new-site.
DB_ROOT_USERNAME=frappe_provisioner
DB_ROOT_PASSWORD=<STRONG_PROVISIONER_PASSWORD>

ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false

# New site's database name and runtime-user password.
DB_NAME=dpuat
DB_PASSWORD=<STRONG_SITE_DATABASE_PASSWORD>
```

For a fresh site:

- `DB_NAME=dpuat` tells `bench new-site` to create/use a database named
  `dpuat`;
- `DB_PASSWORD` becomes the normal site database user's password;
- `DB_ROOT_USERNAME` and `DB_ROOT_PASSWORD` authorize the creation operation;
- `MYSQL_ROOT_PASSWORD` and `MARIADB_ROOT_PASSWORD` belong to local mode and
  are not used to authenticate to the external server.

Do not use `admin`, a reused password, or any password committed to Git.

### 10.2 Run setup

```bash
cd ~/my-frappe-setup/docker-setup
./setup.sh
```

Before confirming setup, verify the displayed target:

```text
Database: external (<DB_PRIVATE_IP>:3306)
```

For a new site, `setup.sh` passes `DB_NAME`, `DB_PASSWORD`, and the temporary
provisioning credentials to `bench new-site`. Frappe then writes the runtime
database name, username, and password into
`sites/<SITE_DOMAIN>/site_config.json` automatically.

Continue at Step 12.

## Step 11: Existing Site Migration

Use a maintenance window. This path moves an existing site from the bundled
MariaDB service to the external server.

### 11.1 Keep the old local database available

Do not run `cleanup.sh`, remove Docker volumes, or delete the local database.
The unchanged local database is the fastest rollback point until external
database acceptance is complete.

Keep the current `.env` in local mode while producing the final backup:

```env
DATABASE_MODE=local
DB_HOST=db
DB_PORT=3306
```

### 11.2 Inspect the current site database identity

```bash
cd ~/my-frappe-setup/docker-setup

docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend jq \
  '{db_name, db_user, db_password:
    (if .db_password then "<redacted>" else null end)}' \
  sites/<SITE_DOMAIN>/site_config.json
```

Record `db_name` and `db_user` securely. Do not paste the real password into a
ticket, screenshot, or chat.

### 11.3 Stop writes and take the final backup

Enable maintenance mode:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend bench --site <SITE_DOMAIN> set-maintenance-mode on
```

Stop background writers:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  stop scheduler queue-short queue-long
```

Create the final backup:

```bash
./backup.sh
```

Verify that the newest backup directory contains non-empty files matching:

```text
*-database.sql.gz
*-files.tar
*-private-files.tar
*-site_config_backup.json
```

Do not allow writes to resume on the old database after this final backup.

### 11.4 Choose the database naming strategy

Choose exactly one option:

#### Option A — preserve the original database identity (recommended)

Create the external database and runtime user with the same `db_name`,
`db_user`, and password already stored in `site_config.json`.

Advantages:

- no `site_config.json` database credential change;
- fewer moving parts during cutover;
- `.env` needs to change only the database server address.

For example, if the current site uses `_example_site_database`, import into that
same database and create that same runtime username on the external server.

#### Option B — rename the imported database

Import into a new name such as `dpuat`, create a runtime user named `dpuat`,
and update the existing site's `site_config.json` once:

```json
{
  "db_name": "dpuat",
  "db_user": "dpuat",
  "db_password": "<STRONG_SITE_DATABASE_PASSWORD>"
}
```

This update cannot be controlled by `DB_NAME=dpuat` in `.env`, because
`setup.sh` uses `DB_NAME` only during new-site creation. Keep every unrelated
key in `site_config.json`, especially `encryption_key`, unchanged.

### 11.5 Create the database and runtime user

Open MariaDB locally on the **Database Server**:

```bash
sudo mariadb
```

For Option B using `dpuat`:

```sql
CREATE DATABASE `dpuat`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER 'dpuat'@'<APP_PRIVATE_IP>'
  IDENTIFIED BY '<STRONG_SITE_DATABASE_PASSWORD>';

GRANT ALL PRIVILEGES ON `dpuat`.*
  TO 'dpuat'@'<APP_PRIVATE_IP>';

FLUSH PRIVILEGES;
SHOW GRANTS FOR 'dpuat'@'<APP_PRIVATE_IP>';
EXIT;
```

If the database or user already exists, inspect it before changing anything:

```sql
SHOW DATABASES LIKE 'dpuat';
SELECT User, Host FROM mysql.user WHERE User = 'dpuat';
SHOW GRANTS FOR 'dpuat'@'<APP_PRIVATE_IP>';
```

Use `ALTER USER` only when intentionally rotating an existing password. Do not
grant the runtime user `*.*` or `WITH GRANT OPTION`.

For Option A, replace `dpuat` in the SQL with the exact existing database and
runtime-user names. MariaDB identifiers containing special characters must
remain enclosed in backticks.

### 11.6 Import the final database dump

Securely copy the final `*-database.sql.gz` file to the Database Server. Then
run on the **Database Server**:

```bash
gzip -dc /path/to/<SITE_DATABASE_BACKUP>-database.sql.gz \
  | sudo mariadb --database=<TARGET_DATABASE_NAME>
```

Verify that tables exist:

```bash
sudo mariadb --execute="
SELECT COUNT(*) AS table_count
FROM information_schema.tables
WHERE table_schema = '<TARGET_DATABASE_NAME>';
"
```

`table_count` must be greater than zero.

If the database was already imported before maintenance mode was enabled, that
copy may be stale. Take and import a new final backup before cutover.

### 11.7 Update `site_config.json` only for Option B

Skip this section for Option A.

Open a shell in the backend container:

```bash
cd ~/my-frappe-setup/docker-setup
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend bash
```

Back up the file and update the non-secret values:

```bash
cd ~/frappe-bench
cp sites/<SITE_DOMAIN>/site_config.json \
  sites/<SITE_DOMAIN>/site_config.json.before-db-name-change

bench --site <SITE_DOMAIN> set-config db_name dpuat
bench --site <SITE_DOMAIN> set-config db_user dpuat
```

Read the password without storing the literal value in shell history, set it,
and immediately clear the shell variable:

```bash
read -rsp "Site database password: " SITE_DATABASE_PASSWORD
printf '\n'
bench --site <SITE_DOMAIN> set-config db_password "$SITE_DATABASE_PASSWORD"
unset SITE_DATABASE_PASSWORD
```

The resulting database keys are:

```json
{
  "db_name": "dpuat",
  "db_user": "dpuat",
  "db_password": "<STRONG_SITE_DATABASE_PASSWORD>"
}
```

Validate the JSON:

```bash
jq empty sites/<SITE_DOMAIN>/site_config.json
```

No output means the JSON is valid.

### 11.8 Test the runtime account before switching

Run on the **App Server**:

```bash
mariadb --protocol=TCP \
  --host=<DB_PRIVATE_IP> \
  --port=3306 \
  --user=<SITE_DB_USER> \
  --password \
  <TARGET_DATABASE_NAME> \
  --execute="SELECT DATABASE(), USER(), CURRENT_USER(); SHOW TABLES;"
```

This must succeed with the same database username and password that the site
will use.

### 11.9 Configure `.env` for the existing site

Edit `docker-setup/.env`:

```env
DATABASE_MODE=external
DB_HOST=<DB_PRIVATE_IP>
DB_PORT=3306

# Preserve the existing local-mode values for rollback.
MYSQL_ROOT_PASSWORD=<EXISTING_LOCAL_DB_ROOT_PASSWORD>
MARIADB_ROOT_PASSWORD=<EXISTING_LOCAL_DB_ROOT_PASSWORD>

# Not required because the DB and runtime user were created manually.
DB_ROOT_USERNAME=
DB_ROOT_PASSWORD=
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false

# Ignored for an existing site; site_config.json is authoritative.
DB_NAME=
DB_PASSWORD=
```

Do not put a MySQL Workbench account in `DB_ROOT_USERNAME`. Do not expect
`DB_NAME=dpuat` here to rewrite an existing `site_config.json`.

### 11.10 Run setup and switch the connection

```bash
cd ~/my-frappe-setup/docker-setup
./setup.sh
```

`setup.sh` will:

1. validate TCP reachability to `<DB_PRIVATE_IP>:3306`;
2. start/recreate Frappe services without starting a new bundled database;
3. run the configurator, which writes `db_host` and `db_port` into
   `sites/common_site_config.json`;
4. detect the existing `<SITE_DOMAIN>` directory;
5. verify that the site can authenticate with `site_config.json`;
6. install/update apps and run migrations.

It will not run `bench new-site` when the existing site is detected, and it
will not use `.env` `DB_NAME`/`DB_PASSWORD` to replace existing credentials.

Continue at Step 12.

## Step 12: Verify the Active External Connection

Check service state on the **App Server**:

```bash
cd ~/my-frappe-setup/docker-setup
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml ps
```

Verify the shared database address:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend cat sites/common_site_config.json
```

Required values:

```json
{
  "db_host": "<DB_PRIVATE_IP>",
  "db_port": 3306
}
```

Verify the site configuration with secrets redacted:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend jq \
  '{db_name, db_user, db_password:
    (if .db_password then "<redacted>" else null end)}' \
  sites/<SITE_DOMAIN>/site_config.json
```

Verify Frappe can query the site:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend bench --site <SITE_DOMAIN> list-apps
```

Verify the connection from inside the backend container:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend python3 -c \
  "import socket; print(socket.create_connection(('<DB_PRIVATE_IP>', 3306), 5).getpeername())"
```

Finally test through the application:

1. Login works.
2. Existing records are present.
3. A permitted record can be created, read, updated, and deleted.
4. Background jobs and scheduled jobs run successfully.
5. Public and private files open correctly.
6. `./backup.sh` creates a non-empty external-database backup.
7. A restore is tested in an approved non-production environment.

For an existing-site migration, disable maintenance mode only after these
checks pass:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend bench --site <SITE_DOMAIN> set-maintenance-mode off
```

Ensure the scheduler and workers are running:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  up -d scheduler queue-short queue-long
```

## Step 13: Remove Temporary Provisioning Access

This step applies to the fresh-site path. Do it only after Step 12 succeeds.

On the **Database Server**:

```bash
sudo mariadb
```

```sql
DROP USER 'frappe_provisioner'@'<APP_PRIVATE_IP>';
FLUSH PRIVILEGES;
EXIT;
```

Clear the temporary credentials from `.env`:

```env
DB_ROOT_USERNAME=
DB_ROOT_PASSWORD=
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false
```

Keep these settings:

```env
DATABASE_MODE=external
DB_HOST=<DB_PRIVATE_IP>
DB_PORT=3306
```

The normal site user stored in `site_config.json` continues to connect to its
own database. The UFW `3306` rule for the App Server must remain.

## Step 14: Rollback Plan

### Before any writes reach the external database

If the cutover fails before external writes are accepted:

1. set `DATABASE_MODE=local`, `DB_HOST=db`, and `DB_PORT=3306` in `.env`;
2. restore the original `site_config.json` if Option B changed it;
3. run `./setup.sh`;
4. verify the site against the unchanged local database;
5. disable maintenance mode only after verification.

### After writes reach the external database

Do not simply point Frappe back to the old local database. It no longer
contains the new writes. Take a new external backup and perform a controlled
reverse migration or restore.

Do not run `cleanup.sh` while the local database volume is being retained for
rollback.

## Optional: MySQL Workbench Access

Use a separate, least-privilege account for administration or reporting. Do not
reuse `frappe_provisioner`, the site runtime account, or MariaDB `root`.

When using **Standard TCP/IP over SSH** to the Database Server:

```text
SSH Hostname:   <DB_PRIVATE_IP>:22
SSH Username:   <SSH_USER>
MySQL Hostname: <DB_PRIVATE_IP>
MySQL Port:     3306
Username:       <WORKBENCH_USER>
```

Because this guide binds MariaDB to `<DB_PRIVATE_IP>`, using `127.0.0.1` as the
MySQL Hostname may fail unless MariaDB is also explicitly configured to listen
on loopback.

A read-only example for one site database is:

```sql
CREATE USER 'workbench_readonly'@'<DB_PRIVATE_IP>'
  IDENTIFIED BY '<STRONG_WORKBENCH_PASSWORD>';

GRANT SELECT, SHOW VIEW ON `dpuat`.*
  TO 'workbench_readonly'@'<DB_PRIVATE_IP>';

FLUSH PRIVILEGES;
```

The MariaDB `Host` value seen through an SSH tunnel is commonly the Database
Server address, not the administrator workstation address. Confirm it in the
actual environment and keep the account limited to the required database.

## Final Acceptance Checklist

- [ ] The deployment is classified as fresh or existing before setup.
- [ ] `<APP_PRIVATE_IP>` comes from `ip route get <DB_PRIVATE_IP>`.
- [ ] MariaDB matches the deployed Frappe branch requirement.
- [ ] MariaDB listens on the private database address only.
- [ ] Host and upstream firewalls allow `3306` only from approved App Servers.
- [ ] `nc -vz -w 5` succeeds from the App Server.
- [ ] MariaDB authentication succeeds with the account required by the chosen path.
- [ ] A fresh site uses `.env` `DB_NAME` and `DB_PASSWORD` during creation.
- [ ] An existing site uses `site_config.json` for its runtime database identity.
- [ ] `common_site_config.json` contains the external `db_host` and `db_port`.
- [ ] Existing records, login, read/write operations, workers, scheduler, and files are verified.
- [ ] A non-empty backup and a non-production restore test are verified.
- [ ] The temporary provisioner is removed after fresh-site acceptance.
- [ ] The rollback database/backup is retained until the cutover is accepted.
