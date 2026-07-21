# Database Client Access Guide

This guide explains how to connect a database client such as MySQL Workbench to the MariaDB service used by this Frappe Docker setup.

## Recommended Production Pattern

For production, avoid exposing the database port to the public network.

Recommended compose mapping:

```yaml
ports:
  - "127.0.0.1:3307:3306"
```

Meaning:

```text
Host 127.0.0.1:3307 -> Docker MariaDB container:3306
```

MariaDB uses `3306` inside the container. The host uses `3307` to avoid conflict with any MySQL/MariaDB already running on the host.

## Same Machine Access

Use this when MySQL Workbench is installed on the same server or same laptop that runs Docker.

MySQL Workbench values:

```text
Connection Method: Standard TCP/IP
Hostname: 127.0.0.1
Port: 3307
Username: root
Password: value of MYSQL_ROOT_PASSWORD or MARIADB_ROOT_PASSWORD from .env
Default Schema: leave blank
```

This works because Workbench connects to the host port `3307`, and Docker forwards it to MariaDB port `3306` inside the container.

## Remote Laptop Access With SSH Tunnel

Use this when MySQL Workbench is on another laptop, but the database port is bound to `127.0.0.1` on the server.

Recommended because the database port stays private.

MySQL Workbench values:

```text
Connection Method: Standard TCP/IP over SSH

SSH Hostname: your-server-ip:22
SSH Username: your-server-ssh-user
SSH Password or SSH Key File: your SSH credential

MySQL Hostname: 127.0.0.1
MySQL Server Port: 3307
Username: root
Password: value of MYSQL_ROOT_PASSWORD or MARIADB_ROOT_PASSWORD from .env
Default Schema: leave blank
```

Connection flow:

```text
Your laptop MySQL Workbench
  -> SSH connection to server
  -> server 127.0.0.1:3307
  -> Docker MariaDB container:3306
```

## Where To Get SSH Password or SSH Key

The SSH credential is not a Frappe password and not a database password. It is the server login credential.

You get it from one of these places:

- Server administrator
- Cloud provider server setup page
- Existing `.pem` or private key file used to login to the server
- Your organization's infrastructure or DevOps team
- The person who created the server

Examples:

```text
SSH username: ubuntu
SSH key file: ~/Downloads/server-key.pem
```

or:

```text
SSH username: deploy
SSH password: server login password
```

Common SSH usernames:

```text
ubuntu
debian
root
deploy
frappe
```

The correct username depends on the server image and how the server was created.

Do not share private SSH keys in chat, email, screenshots, or Git.

## Terminal SSH Tunnel Alternative

Instead of configuring SSH inside MySQL Workbench, you can create the tunnel from your terminal.

Run this from your laptop:

```bash
ssh -L 3307:127.0.0.1:3307 your-server-ssh-user@your-server-ip
```

Keep that terminal open.

Then connect in MySQL Workbench:

```text
Connection Method: Standard TCP/IP
Hostname: 127.0.0.1
Port: 3307
Username: root
Password: value of MYSQL_ROOT_PASSWORD or MARIADB_ROOT_PASSWORD from .env
```

## Internal LAN Direct Access

If you intentionally want other trusted office network laptops to connect without SSH tunnel, bind the database port to the server LAN IP.

Example:

```yaml
ports:
  - "192.168.1.50:3307:3306"
```

Then MySQL Workbench on another office laptop uses:

```text
Hostname: 192.168.1.50
Port: 3307
Username: root
Password: database password
```

This is more open than `127.0.0.1`, so use firewall rules to allow only trusted office IP addresses.

## Less Recommended Broad Mapping

This mapping is convenient but broader:

```yaml
ports:
  - "3307:3306"
```

It may bind to all host network interfaces, similar to:

```yaml
ports:
  - "0.0.0.0:3307:3306"
```

Use it only when you understand the network exposure and firewall rules are in place.

## Security Recommendations

- Prefer `127.0.0.1:3307:3306` plus SSH tunnel for production.
- Do not expose MariaDB to the public internet.
- Use strong database passwords.
- Avoid using the root database user for daily reporting access.
- Create a limited read-only database user if users only need reports.
- Restrict SSH access to trusted administrators.
- Do not commit `.env` or database credentials to Git.

## Troubleshooting

Check whether the DB port is published:

```bash
docker compose ps db
```

Expected for local-only access:

```text
127.0.0.1:3307->3306/tcp
```

Check the running database container:

```bash
docker compose logs db
```

If MySQL Workbench cannot connect:

- Confirm Docker containers are running.
- Confirm the port mapping is correct.
- Confirm you are using port `3307`, not `3306`.
- Confirm the database password from `.env`.
- If using SSH tunnel, confirm SSH login works first.
- If using LAN direct access, confirm firewall allows the client IP.
