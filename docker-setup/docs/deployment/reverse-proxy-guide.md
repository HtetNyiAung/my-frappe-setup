# Reverse Proxy လမ်းညွှန်

Frappe Docker Site ကို Public HTTPS Domain ဖြင့် အသုံးပြုနိုင်ရန် Reverse Proxy
ချိတ်ဆက်နည်းဖြစ်သည်။ အကြံပြု Production flow—

```text
User Browser
  -> https://app.example.com
  -> Reverse Proxy on App Server
  -> http://127.0.0.1:8787
  -> Docker frontend container:8080
```

Frappe Docker App port ကို Public Internet သို့ တိုက်ရိုက်မဖွင့်ပါနှင့်။

## 1. `.env` Values

Internal Frappe Site name နှင့် Public Domain ကို သီးခြားထားပါ။

```env
SITE_DOMAIN=frontend
PUBLIC_URL=https://app.example.com
FRAPPE_PORT=8787
FRAPPE_INTERNAL_PORT=8080
BIND_ADDRESS=127.0.0.1
```

- `SITE_DOMAIN` — Internal Frappe Site name။
- `PUBLIC_URL` — User Browser တွင်ဖွင့်မည့် URL။
- `BIND_ADDRESS=127.0.0.1` — Docker frontend port ကို Host တစ်လုံးအတွင်းမှသာ
  ရောက်နိုင်စေသည်။ Public traffic သည် Reverse Proxy ဖြင့်သာဝင်ရမည်။

Internal Container Nginx configuration ကို နားလည်ပြီး သက်ဆိုင်ရာ Config
အားလုံးပြင်ခြင်းမရှိပါက `FRAPPE_INTERNAL_PORT=8080` ကို မပြောင်းပါနှင့်။

## 2. DNS Setup

DNS provider တွင် Record ဖန်တီးပါ။

```text
Type: A
Name: app
Value: <app-server-public-ip>
```

DNS resolve ဖြစ်ကြောင်း စစ်ပါ။

```bash
nslookup app.example.com
dig app.example.com
```

## 3. Frappe Stack စတင်ခြင်း

```bash
cd <project-path>/docker-setup
docker compose up -d
docker compose ps
curl -I http://127.0.0.1:8787
```

နောက်ပိုင်းရှိ command များတွင် Domain, Site name, Path နှင့် Port ကို မိမိ
Environment အမှန်ဖြင့် ပြောင်းပါ။

## 4. Frappe Public URL သတ်မှတ်ခြင်း

```bash
cd <project-path>/docker-setup
docker compose exec backend bench --site frontend set-config host_name https://app.example.com
docker compose exec backend bench --site frontend clear-cache
```

`setup.sh` သည် `.env` ရှိ `PUBLIC_URL` ကို Setup/Reconfigure အတွင်း Apply
လုပ်နိုင်သည်။

## 5. Nginx Reverse Proxy

```bash
sudo apt update
sudo apt install nginx
sudo nano /etc/nginx/sites-available/frappe-app.conf
```

နမူနာ Config—

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

```bash
sudo ln -s /etc/nginx/sites-available/frappe-app.conf /etc/nginx/sites-enabled/frappe-app.conf
sudo nginx -t
sudo systemctl reload nginx
```

Existing Symlink/config များရှိ/မရှိ စစ်ပြီးမှ `ln -s` လုပ်ပါ။ `nginx -t`
မအောင်မြင်ပါက Reload မလုပ်ဘဲ Error ကိုအရင်ပြင်ပါ။

## 6. Certbot ဖြင့် HTTPS ဖွင့်ခြင်း

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d app.example.com
sudo certbot renew --dry-run
```

Certificate ထုတ်ရန် DNS သည် Server အမှန်ကိုညွှန်ပြီး Ports `80`/`443`
ရောက်နိုင်ရမည်။ ပြီးလျှင် `https://app.example.com` ကိုသုံးပါ။

## 7. Caddy Alternative

Caddy သည် HTTPS Certificate ကို အလိုအလျောက်ထုတ်/သက်တမ်းတိုးနိုင်သည်။

```bash
sudo nano /etc/caddy/Caddyfile
```

```caddyfile
app.example.com {
    reverse_proxy 127.0.0.1:8787
    encode gzip
    request_body {
        max_size 50MB
    }
}
```

```bash
sudo systemctl reload caddy
```

## 8. Firewall

Public ဖွင့်ရန်—

```text
80  HTTP redirect to HTTPS
443 HTTPS
22  SSH (Approved Admin sources only)
```

Public မဖွင့်ရန်—

```text
3306 / 3307  MariaDB
8080         Internal Frappe frontend
8787         Docker frontend host port
9000         Internal WebSocket or Storage port, depending on the host
```

`BIND_ADDRESS=127.0.0.1` ဖြစ်ပါက `8787` သည် Local-only ဖြစ်သည်။

## 9. Verification

```bash
curl -I http://127.0.0.1:8787
curl -I https://app.example.com
curl -I http://app.example.com
```

HTTPS မှ `200`၊ HTTP မှ HTTPS သို့ `301`/`308` Redirect ရသင့်သည်။ Browser မှ—

- Public HTTPS URL ဖွင့်ပါ။
- Administrator Login ဝင်ပြီး Desk/Main page ဖွင့်ပါ။
- `Ctrl + Shift + R` ဖြင့် Hard Refresh လုပ်ပါ။
- `:8080`/`:8787` သို့ Redirect မဖြစ်ကြောင်းစစ်ပါ။
- Realtime notification နှင့် File upload စမ်းပါ။

## 10. ပြဿနာဖြေရှင်းခြင်း

### Browser က `:8080` သို့ Redirect ဖြစ်ခြင်း

Internal frontend Nginx က Container port ပါသည့် Absolute Redirect ထုတ်ခြင်း
ဖြစ်နိုင်သည်။ Template ထဲတွင် အောက်ပါ Settings လိုနိုင်သည်။

```nginx
absolute_redirect off;
port_in_redirect off;
```

```bash
docker compose restart frontend
```

### Public Domain တွင် `connection refused`

DNS, Reverse Proxy service, Firewall `80`/`443` နှင့်
`curl -I http://127.0.0.1:8787` ကို အစဉ်လိုက်စစ်ပါ။

### WebSocket/Realtime မလုပ်ခြင်း

Reverse Proxy တွင် Upgrade Headers ပါကြောင်းစစ်ပါ။

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

### File Upload မအောင်မြင်ခြင်း

လိုအပ်မှသာ Compose နှင့် Reverse Proxy နှစ်နေရာလုံးတွင် Limit တူအောင်တိုးပါ။

```yaml
CLIENT_MAX_BODY_SIZE: 50m
```

```nginx
client_max_body_size 50m;
```

## 11. Production မှတ်ချက်

- Docker frontend ကို `127.0.0.1` တွင် Bind ပါ။
- Public HTTPS အတွက် Reverse Proxy ကိုသုံးပါ။
- Database/Redis/Internal ports ကို Private ထားပါ။
- `PUBLIC_URL` ကို HTTPS URL အမှန် သတ်မှတ်ပါ။
- Site ကို Rename လုပ်ရန်မဟုတ်ပါက `SITE_DOMAIN` မပြောင်းပါနှင့်။
- Go-Live မတိုင်မီ Backup/Restore စမ်းပြီး `.env` ကို Secret အဖြစ်ကာကွယ်ပါ။
