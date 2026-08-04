# Reverse Proxy Guide

This guide explains how to expose a Frappe Docker site through a public HTTPS domain using a reverse proxy.

The recommended production pattern is:

```text
User Browser
  -> https://app.example.com
  -> Reverse proxy on host server
  -> http://127.0.0.1:8787
  -> Docker frontend container:8080
```

The Frappe Docker app should not be exposed directly to the public internet.

## 1. Recommended `.env` Values

Keep the internal Frappe site name separate from the public domain.

```env
SITE_DOMAIN=frontend
PUBLIC_URL=https://app.example.com
FRAPPE_PORT=8787
FRAPPE_INTERNAL_PORT=8080
BIND_ADDRESS=127.0.0.1
```

Meaning:

```text
SITE_DOMAIN=frontend
```

This is the internal Frappe site name.

```text
PUBLIC_URL=https://app.example.com
```

This is the URL users open in the browser.

```text
BIND_ADDRESS=127.0.0.1
```

This means the Docker frontend port is available only on the server itself. The public internet should reach the app only through the reverse proxy.

Do not change `FRAPPE_INTERNAL_PORT=8080` unless you also understand the internal container Nginx configuration.

## 2. DNS Setup

Create a DNS record:

```text
Type: A
Name: app
Value: your-server-public-ip
```

Example:

```text
app.example.com -> 203.0.113.10
```

Wait until DNS resolves:

```bash
nslookup app.example.com
```

or:

```bash
dig app.example.com
```

## 3. Start the Frappe Docker Stack

Run:

```bash
cd /path/to/docker-setup
docker compose up -d
```

Check containers:

```bash
docker compose ps
```

The Frappe app should be reachable from the server itself:

```bash
curl -I http://127.0.0.1:8787
```

## 4. Set Frappe Public URL

Set the public host name:

```bash
cd /path/to/docker-setup
docker compose exec backend bench --site frontend set-config host_name https://app.example.com
docker compose exec backend bench --site frontend clear-cache
```

If `setup.sh` supports `PUBLIC_URL`, this can be applied automatically during setup.

## 5. Nginx Reverse Proxy Example

Install Nginx on the host server:

```bash
sudo apt update
sudo apt install nginx
```

Create a site config:

```bash
sudo nano /etc/nginx/sites-available/frappe-app.conf
```

Example config:

```nginx
server {
    listen 80;
    server_name app.example.com;

    client_max_body_size 50m;

    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;

        proxy_read_timeout 120s;
        proxy_send_timeout 120s;
    }

    location /socket.io {
        proxy_pass http://127.0.0.1:8787;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_read_timeout 120s;
        proxy_send_timeout 120s;
    }
}
```

Enable the config:

```bash
sudo ln -s /etc/nginx/sites-available/frappe-app.conf /etc/nginx/sites-enabled/frappe-app.conf
sudo nginx -t
sudo systemctl reload nginx
```

## 6. Enable HTTPS With Certbot

Install Certbot:

```bash
sudo apt install certbot python3-certbot-nginx
```

Issue a certificate:

```bash
sudo certbot --nginx -d app.example.com
```

Test renewal:

```bash
sudo certbot renew --dry-run
```

After this, users should open:

```text
https://app.example.com
```

## 7. Caddy Reverse Proxy Alternative

Caddy can manage HTTPS certificates automatically.

Install Caddy, then create:

```bash
sudo nano /etc/caddy/Caddyfile
```

Example:

```caddyfile
app.example.com {
    reverse_proxy 127.0.0.1:8787

    encode gzip

    request_body {
        max_size 50MB
    }
}
```

Reload Caddy:

```bash
sudo systemctl reload caddy
```

Caddy automatically requests and renews HTTPS certificates if DNS points to the server and ports `80` and `443` are open.

## 8. Firewall Rules

Recommended public ports:

```text
80  HTTP, redirect to HTTPS
443 HTTPS
22  SSH, restricted to admins if possible
```

Avoid exposing:

```text
3306 / 3307  MariaDB
8080         internal Frappe frontend port
8787         Docker frontend host port
9000         websocket internal port
```

If `BIND_ADDRESS=127.0.0.1`, port `8787` is already local-only.

## 9. Verification

Check local app:

```bash
curl -I http://127.0.0.1:8787
```

Check public HTTPS:

```bash
curl -I https://app.example.com
```

Expected:

```text
HTTP/2 200
```

or:

```text
HTTP/1.1 200 OK
```

Check that HTTP redirects to HTTPS:

```bash
curl -I http://app.example.com
```

Expected:

```text
301 or 308 redirect to https://app.example.com
```

Check browser:

- Open `https://app.example.com`
- Login as Administrator
- Open Desk or the main application page
- Hard refresh with `Ctrl + Shift + R`
- Confirm the browser does not redirect to port `8080` or `8787`

## 10. Common Problems

### Browser redirects to `:8080`

This usually means the internal frontend Nginx generated an absolute redirect with its container port.

In the Docker frontend Nginx template, use:

```nginx
absolute_redirect off;
port_in_redirect off;
```

Then restart the frontend container:

```bash
docker compose restart frontend
```

### Public domain shows connection refused

Check:

- DNS points to the server IP.
- Reverse proxy is running.
- Firewall allows ports `80` and `443`.
- Docker frontend is running on `127.0.0.1:8787`.

### Websocket or realtime features do not work

Check that the reverse proxy supports websocket upgrade headers:

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### File upload fails

Increase upload size in both places:

Docker compose:

```yaml
CLIENT_MAX_BODY_SIZE: 50m
```

Reverse proxy:

```nginx
client_max_body_size 50m;
```

Use a larger value only if the application requires large uploads.

## 11. Production Notes

- Keep Docker frontend bound to `127.0.0.1`.
- Use reverse proxy for public HTTPS.
- Keep database ports private.
- Set `PUBLIC_URL` to the real HTTPS URL.
- Do not change `SITE_DOMAIN` unless intentionally renaming the Frappe site.
- Test backup and restore before go-live.
- Keep `.env` private.
