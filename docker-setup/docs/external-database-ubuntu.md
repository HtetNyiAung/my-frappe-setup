# External MariaDB on an Ubuntu VM

This guide provisions a separate Ubuntu virtual machine as the MariaDB server
for this Frappe Docker setup. It covers the database host itself. For switching
Frappe between local and external database modes, migrating an existing site,
and rollback, use [External MariaDB](external-database.md).

The commands use placeholders. Replace every value in angle brackets before
running a command:

```text
<APP_PRIVATE_IP>   Private IP of the Frappe Docker host
<DB_PRIVATE_IP>    Private IP of the MariaDB VM
<ADMIN_PRIVATE_IP> Approved administrator or VPN source IP
<DB_PRIVATE_DNS>   Optional private DNS name for the database VM
```

Do not use public IP addresses for database traffic. Do not open MariaDB port
`3306` to `0.0.0.0/0` or the public internet.

## 1. Choose the Topology

The supported traffic path is:

```text
Frappe containers
  -> Frappe host private network
  -> MariaDB VM private IP:3306
```

Before provisioning, confirm:

- The Frappe host and database VM can communicate through a private network or
  an approved VPN.
- The database VM has a stable private IP or private DNS record.
- The database disk is persistent and is not an ephemeral instance disk.
- Database backups will be copied to storage outside the database VM.
- The application and database clocks use NTP.
- An approved maintenance and rollback window exists for an existing site.

This project currently tests against MariaDB `10.6`. Do not switch to a new
MariaDB major series without staging migration and application tests. MariaDB
publishes packages for the 10.6 series on supported Ubuntu LTS releases; check
the current [MariaDB repository documentation](https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/installing-mariadb/binary-packages/mariadb-package-repository-setup-and-usage)
before installing.

## 2. Prepare Ubuntu

Log in through the private network or VPN and confirm the operating system:

```bash
cat /etc/os-release
uname -m
timedatectl status
lsblk -f
df -h
```

Apply operating-system updates before installing MariaDB:

```bash
sudo apt update
sudo apt upgrade
sudo reboot
```

After reconnecting, install the basic administration tools:

```bash
sudo apt update
sudo apt install -y ca-certificates curl ufw
```

For production, place `/var/lib/mysql` on persistent storage sized for current
data, indexes, temporary work, binary logs, and growth. Monitor both free bytes
and free inodes. Do not move an existing MariaDB data directory by copying live
files; use a controlled migration or restore procedure.

## 3. Install MariaDB 10.6

Use MariaDB's repository setup utility to select the tested major series. Read
the downloaded script before executing it when required by the organization's
supply-chain policy:

```bash
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup \
  -o /tmp/mariadb_repo_setup
less /tmp/mariadb_repo_setup
sudo bash /tmp/mariadb_repo_setup \
  --mariadb-server-version=mariadb-10.6
sudo apt update
sudo apt install -y mariadb-server mariadb-client mariadb-backup
```

The official [MariaDB installation guide](https://mariadb.com/docs/server/mariadb-quickstart-guides/installing-mariadb-server-guide)
describes the package installation and service setup.

Enable the service and verify the selected version:

```bash
sudo systemctl enable --now mariadb
sudo systemctl status mariadb --no-pager
sudo mariadb --version
sudo mariadb-admin ping
```

The repository should remain on the `10.6` major series while still receiving
minor security and bug-fix updates. Do not hold all MariaDB packages indefinitely
because that would also block security updates.

## 4. Apply Frappe-Compatible Server Settings

Create a dedicated configuration file instead of editing package-owned files:

```bash
sudoedit /etc/mysql/mariadb.conf.d/60-frappe.cnf
```

Use the database VM's private IP:

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

Do not set a fixed `innodb-buffer-pool-size` copied from another server. Size it
after considering total VM memory, database-only usage, connection count, and
monitoring data.

Validate the configuration before restarting:

```bash
sudo mariadbd --validate-config
sudo systemctl restart mariadb
sudo systemctl status mariadb --no-pager
```

If the installed 10.6 package does not support `--validate-config`, inspect the
effective options and service log instead:

```bash
sudo my_print_defaults mariadbd
sudo journalctl -u mariadb -n 100 --no-pager
```

Confirm the listener is bound to the private address and not every interface:

```bash
sudo ss -lntp | grep ':3306'
```

Confirm the database defaults:

```bash
sudo mariadb -e "SHOW VARIABLES WHERE Variable_name IN \
('character_set_server','collation_server','innodb_file_per_table','max_allowed_packet');"
```

## 5. Harden MariaDB

Run the vendor hardening utility:

```bash
sudo mariadb-secure-installation
```

Remove anonymous users and the test database. Keep administrative root access
local to the database VM. Do not enable remote root login.

On Ubuntu, local root administration commonly uses Unix socket authentication:

```bash
sudo mariadb
```

Check that no unrestricted remote administrative account exists:

```sql
SELECT User, Host, plugin
FROM mysql.user
ORDER BY User, Host;
```

Do not paste real passwords into documentation, tickets, chat, shell history,
or committed files.

## 6. Configure the Firewall

First allow SSH from the approved administration source. Verify the exact
source range before enabling UFW, otherwise the active SSH session can be
locked out:

```bash
sudo ufw allow from <ADMIN_PRIVATE_IP> to any port 22 proto tcp
sudo ufw allow from <APP_PRIVATE_IP> to <DB_PRIVATE_IP> port 3306 proto tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw status numbered
```

Apply the same source restriction in the cloud firewall, security group, or
hypervisor firewall. Host firewall rules do not replace infrastructure firewall
rules.

From any unapproved host, port `3306` should be unreachable. From the Frappe
host it should accept a TCP connection:

```bash
nc -vz <DB_PRIVATE_IP> 3306
```

## 7. Create a Temporary Provisioning Account

For a fresh site, `setup.sh` passes `DB_ROOT_USERNAME` and `DB_ROOT_PASSWORD` to
`bench new-site`. That account must be able to create the site database, create
the runtime user, and grant that runtime user permissions.

Create a temporary account restricted to the Frappe host's private IP:

```bash
sudo mariadb
```

```sql
CREATE USER 'frappe_provisioner'@'<APP_PRIVATE_IP>'
  IDENTIFIED BY '<STRONG_PROVISIONING_PASSWORD>';
GRANT ALL PRIVILEGES ON *.*
  TO 'frappe_provisioner'@'<APP_PRIVATE_IP>' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

This is intentionally an administrative account because fresh-site creation
must create and grant access to a database that does not exist yet. Its host is
restricted, but it is still highly privileged. Use it only for provisioning.

After the site has been created and verified, remove its credentials from the
application `.env` and drop the account if automated provisioning and external
credential repair are not required:

```sql
DROP USER 'frappe_provisioner'@'<APP_PRIVATE_IP>';
```

Keep `ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false` during normal operation.

For an existing-site migration, do not create a new random runtime user. Follow
the migration section in [External MariaDB](external-database.md) and recreate
the database/user values already recorded in the site's `site_config.json`.

## 8. Configure the Frappe Host

On the Frappe Docker host, update `.env`:

```env
DATABASE_MODE=external
DB_HOST=<DB_PRIVATE_IP_OR_PRIVATE_DNS>
DB_PORT=3306
DB_ROOT_USERNAME=frappe_provisioner
DB_ROOT_PASSWORD=<STRONG_PROVISIONING_PASSWORD>
DB_NAME=
DB_PASSWORD=<STRONG_SITE_DATABASE_PASSWORD>
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false
```

`DB_HOST` must resolve inside the Frappe containers. Do not use `localhost` or
`127.0.0.1`, because those point back to each individual container.

Confirm TCP connectivity from the backend container before provisioning:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend python -c \
  "import socket; socket.create_connection(('<DB_PRIVATE_IP>', 3306), 5).close(); print('database TCP reachable')"
```

For a fresh site, run:

```bash
./setup.sh
```

Review the displayed database target before typing `SETUP`. The script performs
its own TCP and database credential checks.

For an existing site, stop here and follow
[Existing Site Migration](external-database.md#existing-site-migration).
Changing `DB_HOST` does not copy database records.

## 9. Verify the Fresh Site

After `setup.sh` succeeds, check the application from the Frappe host:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml ps
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend bench --site frontend list-apps
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml \
  exec backend bench --site frontend doctor
```

Replace `frontend` with the actual `SITE_DOMAIN` value. Then verify:

- Administrator login works.
- A test record can be created, read, updated, and deleted.
- Queue workers process jobs.
- The scheduler is enabled and healthy.
- File upload and download work for the configured local or S3 storage mode.
- `./backup.sh` creates a complete, non-empty backup set.
- A restore succeeds on a non-production test site.

On the database VM, confirm the runtime account is scoped to its site database:

```sql
SELECT User, Host
FROM mysql.user
ORDER BY User, Host;

SHOW GRANTS FOR '<SITE_DB_USER>'@'<APP_PRIVATE_IP>';
```

Use the actual runtime username from `site_config.json`. It should not have
global administrative privileges.

## 10. Configure Independent Database Backups

`backup.sh` on the Frappe host creates logical Frappe backups. Keep using it.
Also operate a database-server backup so database recovery does not depend on
the application VM.

Install `mariadb-backup` as shown earlier and create a local-only backup account.
MariaDB documents the privileges needed by its backup utility in the
[mariadb-backup overview](https://mariadb.com/docs/server/server-usage/backup-and-restore/mariadb-backup/mariadb-backup-overview).

Example account:

```sql
CREATE USER 'mariadb_backup'@'localhost'
  IDENTIFIED BY '<STRONG_BACKUP_PASSWORD>';
GRANT RELOAD, PROCESS, LOCK TABLES, BINLOG MONITOR ON *.*
  TO 'mariadb_backup'@'localhost';
FLUSH PRIVILEGES;
```

Store backup credentials in a root-readable MariaDB option file rather than a
command-line argument:

```bash
sudo install -m 600 /dev/null /root/.mariadb-backup.cnf
sudoedit /root/.mariadb-backup.cnf
```

```ini
[client]
user=mariadb_backup
password=<STRONG_BACKUP_PASSWORD>
```

Create a full backup on storage that is not the MariaDB data directory:

```bash
sudo install -d -m 700 /srv/mariadb-backups
sudo mariadb-backup \
  --defaults-extra-file=/root/.mariadb-backup.cnf \
  --backup \
  --target-dir=/srv/mariadb-backups/full-$(date +%F_%H-%M-%S)
```

Automate this command with a root-owned systemd timer or an approved backup
platform. Add all of the following controls:

- One-run-at-a-time locking.
- Free-space preflight.
- Success-gated retention.
- Backup logs and alerting.
- Encrypted off-host copy.
- Regular restore testing on a disposable VM.

A backup is not proven until it has been prepared and restored successfully.
Do not test a physical restore over the live production data directory. Follow
MariaDB's documented prepare/restore procedure on an isolated VM using the same
MariaDB major series.

## 11. TLS Boundary

Use a private network or VPN even when TLS is enabled. MariaDB can be configured
with server and client certificates, but this Docker setup does not currently
map database TLS options from `.env` into Frappe's connection configuration.

Do not enforce TLS-only database accounts until application-side certificate
and verification settings have been implemented and tested. If database traffic
must cross an untrusted network, add that support first or place both hosts
behind an approved VPN. Plain database traffic over the public internet is not
supported.

## 12. Daily Operations

Check service health and recent errors:

```bash
sudo systemctl status mariadb --no-pager
sudo mariadb-admin ping
sudo journalctl -u mariadb --since '24 hours ago' --no-pager
df -h /var/lib/mysql /srv/mariadb-backups
df -i /var/lib/mysql /srv/mariadb-backups
```

Monitor at least:

- Disk space and inode usage.
- Backup age and restore-test status.
- Active and maximum connections.
- Slow queries and lock waits.
- MariaDB service restarts.
- Replication lag, if replication is later introduced.
- Operating-system and MariaDB security updates.

Apply MariaDB minor updates during a controlled maintenance window after a
verified backup. Test major-version upgrades outside production first.

## 13. Troubleshooting

### Connection Refused

Check the service, listener, host firewall, cloud firewall, and private route:

```bash
sudo systemctl status mariadb --no-pager
sudo ss -lntp | grep ':3306'
sudo ufw status numbered
sudo journalctl -u mariadb -n 100 --no-pager
```

### Access Denied

Confirm the MariaDB account's `Host` matches the source IP observed by the
database server. Docker traffic commonly arrives as the Frappe VM's private IP,
but this depends on network routing.

```sql
SELECT User, Host
FROM mysql.user
ORDER BY User, Host;
```

Do not solve access errors by changing the host to `%` or granting global
privileges to the runtime site user.

### Incorrect Character Set

Verify the server defaults and the site database:

```sql
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';
SHOW CREATE DATABASE `<SITE_DATABASE_NAME>`;
```

Do not convert a production database without a verified backup and staging
test.

## Production Acceptance Checklist

- [ ] MariaDB uses the tested major series.
- [ ] Database storage is persistent and monitored.
- [ ] Port `3306` is reachable only from the Frappe private source.
- [ ] Remote root login is disabled.
- [ ] No account uses `%` unless explicitly approved and justified.
- [ ] The temporary provisioner was removed after fresh-site creation.
- [ ] The runtime site user has permissions only on its own database.
- [ ] Character set and collation are correct.
- [ ] Frappe workers and scheduler are healthy.
- [ ] Frappe and database-server backups both run successfully.
- [ ] Backups are copied off-host and restore-tested.
- [ ] Rollback steps were reviewed before accepting production writes.
