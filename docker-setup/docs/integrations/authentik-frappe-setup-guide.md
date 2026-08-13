# Frappe/ERPNext အတွက် Authentik Setup လမ်းညွှန်

Repository တွင်ပါသော Authentik Identity Provider (IdP) ကို စတင်ပြီး Frappe နှင့်
Single Sign-On (SSO) ချိတ်ရန် အခြေခံလမ်းညွှန်ဖြစ်သည်။ Authentik ၏ UI/Flow သည်
Version အလိုက်ကွာနိုင်သောကြောင့် Production ချိတ်ဆက်မှုတွင် သက်ဆိုင်ရာ Version
၏ Official Documentation ဖြင့် Endpoint/Screen names ကိုလည်း စစ်ပါ။

## Architecture

`docker-compose.authentik.yml` တွင်—

1. `authentik-db` — PostgreSQL Configuration/User/Token Data
2. `authentik-redis` — Cache, Session နှင့် Background Queue
3. `authentik-server` — UI, Authentication နှင့် API
4. `authentik-worker` — Email, Synchronization နှင့် Cleanup tasks

ပါဝင်သည်။ Stack သည် Frappe containers နှင့် Private Network မှ ဆက်သွယ်နိုင်ရန်
`frappe_network` သို့ ချိတ်ထားသည်။ Authentik Admin UI/Database/Redis ကို Public
မဖွင့်ပါနှင့်။

## `.env` ပြင်ဆင်ခြင်း

```env
AUTHENTIK_PORT=9000
AUTHENTIK_HTTPS_PORT=9443
AUTHENTIK_DB_PASSWORD=<strong-database-password>
AUTHENTIK_DB_NAME=authentik
AUTHENTIK_DB_USER=authentik
AUTHENTIK_SECRET_KEY=<strong-random-secret>
AUTHENTIK_TAG=<approved-version-tag>
AUTHENTIK_BOOTSTRAP_PASSWORD=<strong-bootstrap-password>
AUTHENTIK_BOOTSTRAP_EMAIL=admin@example.com
```

Strong Secret ထုတ်ရန်—

```bash
openssl rand -base64 64 | tr -d '\n'
```

`AUTHENTIK_SECRET_KEY` ကို နောက်မှပြောင်းပါက Existing Sessions နှင့် Encrypted
configuration များ ပျက်နိုင်သည်။ Secret အဖြစ် Backup လုပ်ပြီး Git မထည့်ပါနှင့်။
Production တွင် HTTP Admin port ကို Public expose မလုပ်ဘဲ HTTPS Reverse Proxy,
VPN သို့မဟုတ် Management Network သုံးပါ။

## Stack စတင်ခြင်း

Frappe နှင့် Authentik တွဲစတင်ရန်—

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.authentik.yml up -d
```

Authentik သီးခြားစတင်ရန်—

```bash
docker compose -f docker-compose.authentik.yml --env-file .env up -d
```

ပထမဆုံး Run တွင် Database Provisioning ကြောင့် မိနစ်အနည်းငယ်ကြာနိုင်သည်။

```bash
docker logs -f authentik-server
```

Local Development တွင် `http://localhost:9000/` ကိုဖွင့်ပြီး `akadmin` နှင့်
`.env` ရှိ Bootstrap password ဖြင့် Login ဝင်ပါ။ Bootstrap credentials
မသတ်မှတ်ထားပါက—

```text
http://localhost:9000/if/flow/initial-setup/
```

Production Public URL အတွက် `localhost` မသုံးပါနှင့်။ OAuth/OIDC Provider,
Redirect URI, Client ID/Secret နှင့် Claims ကို Authentik/Frappe နှစ်ဖက်လုံးတွင်
HTTPS URL အမှန်ဖြင့် တိတိကျကျကိုက်ညီအောင် ပြင်ပါ။

## Persistent Data

- `authentik_db_data` — PostgreSQL Data
- `authentik_redis_data` — Redis Data
- `./authentik_media` — Branding media/icons
- `./authentik_custom_templates` — UI templates
- `./authentik_certs` — Certificates/Keys

Database, Media, Templates, Certificates နှင့် `AUTHENTIK_SECRET_KEY` ကို Backup
နယ်ပယ်ထဲ ထည့်ပါ။

## ပြဿနာဖြေရှင်းခြင်း

### `akadmin` Password Reset

```bash
docker compose -f docker-compose.authentik.yml exec authentik-server python3 manage.py changepassword akadmin
```

Container run နေရမည်ဖြစ်ပြီး Terminal prompt တွင် Strong password အသစ်ထည့်ပါ။

### `/media/public` Permission Error

`chmod -R 777` ကို Production fix အဖြစ် မသုံးပါနှင့်။ Container ကသုံးသော UID/GID
နှင့် Current ownership ကိုအရင်စစ်ပြီး လိုအပ်သော Directory ကိုသာ ownership/
minimum permission ပြင်ပါ။

```bash
ls -ld ./authentik_media ./authentik_certs ./authentik_custom_templates
docker compose -f docker-compose.authentik.yml logs authentik-server authentik-worker
```

ပြင်ပြီးနောက်—

```bash
docker compose -f docker-compose.authentik.yml restart authentik-server authentik-worker
```

## Stop နှင့် Remove

Data မဖျက်ဘဲ Stop—

```bash
docker compose -f docker-compose.authentik.yml stop
```

Containers ဖယ်ရှားသော်လည်း Named Volumes ထားရန်—

```bash
docker compose -f docker-compose.authentik.yml down
```

`down -v` သည် Database volumes ကိုဖျက်သော destructive command ဖြစ်သောကြောင့်
Verified Backup နှင့် Explicit approval မရှိဘဲ မသုံးပါနှင့်။
