# Frappe Docker ပထမဆုံး Setup လမ်းညွှန်

`setup.sh` သည် Site ကို ပထမဆုံး Install လုပ်ရန်နှင့် Infrastructure
configuration ကို ရည်ရွယ်ချက်ရှိရှိ ပြန်ပြင်ရန်သုံးသော Script ဖြစ်သည်။
`apps.json` မှ Custom image ဆောက်ခြင်း၊ Docker Compose စတင်ခြင်း၊ Site
ဖန်တီးခြင်း၊ Apps install လုပ်ခြင်း၊ Storage/Branding ပြင်ခြင်းနှင့် UI Cache
ရှင်းခြင်းတို့ကို လုပ်ပေးသည်။ ပုံမှန် Code update အတွက် မသုံးပါနှင့်။

## အမြန်စတင်နည်း

`docker-setup` folder မှ run ပါ။

```bash
chmod +x setup.sh deploy.sh ops.sh backup.sh restore.sh
./setup.sh
```

Script သည် target Site, image, rebuild mode နှင့် S3 mode ကို ပြပြီး Stack
မပြောင်းမီ `SETUP` ဟု အတည်ပြုခိုင်းသည်။ ယုံကြည်ရသော Automation မှသာ
`./setup.sh --yes` ကို သုံးပါ။

Local Site ကို `.env` ရှိ port ဖြင့်ဖွင့်ပါ။ Default နမူနာ—

```text
http://localhost:8787
```

## First Setup နှင့် နောက်ပိုင်း Operations

Stack နှင့် Site ကို ပထမဆုံးဖန်တီးသည့်အခါ—

```bash
./setup.sh
```

Running Backend တွင် `SITE_DOMAIN` ရှိပြီးသားဆိုလျှင် ပုံမှန် Setup သည် ရပ်ပြီး
`deploy.sh` သုံးရန် ပြောမည်။ ထို Guard ကြောင့် နေ့စဉ် Code update တစ်ခုက
Provisioning workflow တစ်ခုလုံးကို မတော်တဆ run မိခြင်းမှ ကာကွယ်ပေးသည်။

ရှိပြီးသား Site ၏ Infrastructure configuration ကို ရည်ရွယ်ချက်ရှိရှိ
ပြောင်းရန်—

```bash
./setup.sh --reconfigure
```

Image အသစ်လည်း ဆောက်ရန်လိုမှ—

```bash
./setup.sh --reconfigure --rebuild
```

ပုံမှန် Code/App update အတွက်—

```bash
./deploy.sh check
./deploy.sh plan
./deploy.sh apply
```

`--reconfigure` ကို အောက်ပါအချိန်များတွင် သုံးပါ။

- Local/External Database infrastructure settings ပြောင်းခြင်း။
- Custom App mounts သို့မဟုတ် generated Compose config ပြန်ဖန်တီးခြင်း။
- Setup ကစီမံသော S3, Public URL သို့မဟုတ် Branding ပြောင်းခြင်း။

နောက်ပိုင်း Operation များအတွက် [Deployment လမ်းညွှန်](../deployment/deploy.md)
နှင့် [Runtime Operations လမ်းညွှန်](../operations/operations.md) ကို ဖတ်ပါ။

## `apps.json`

`apps.json` သည် Image ထဲပါမည့် Frappe Apps နှင့် Site တွင် Install လုပ်မည့်
Apps များကို သတ်မှတ်သည်။

```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-16",
    "is_custom": false
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-16",
    "is_custom": false
  }
]
```

- ပုံမှန် Frappe App — `"is_custom": false`
- Local Development/Custom App — `"is_custom": true`

Custom Apps များကို အောက်ပါနေရာသို့ Clone လုပ်ပြီး `setup.sh` က
`docker-compose.override.yml` ကို အလိုအလျောက်ပြန်ဖန်တီးကာ လိုအပ်သော
Containers များတွင် Mount လုပ်သည်။ Generated override ကို Manual မပြင်ပါနှင့်။

```text
docker-setup/frappe_docker/apps/<app-name>
```

### Private GitHub Repository

Credential ကို Repository URL ထဲ မထည့်ပါနှင့်။ Private App ကို ရှင်းလင်းစွာ
သတ်မှတ်ပါ။

```json
{
  "name": "private_app",
  "url": "https://github.com/OWNER/private-app.git",
  "branch": "main",
  "is_custom": true,
  "private": true
}
```

Fine-grained GitHub token ကို Git က ignore လုပ်ထားသော `.env` ထဲတွင်သာ
သိမ်းပါ။

```env
GITHUB_TOKEN=<FINE_GRAINED_GITHUB_TOKEN>
```

Token တွင် `private: true` App repositories အားလုံးအတွက် read-only
**Contents** permission ရှိရမည်။ Setup သည် Host-side Git operation တွင်
Temporary HTTP authorization header သုံးပြီး Docker build တွင် mode `600`
Temporary `apps.json` ကို BuildKit secret အဖြစ်ပေးသည်။ Build ပြီးလျှင် Temporary
file ကိုဖျက်ပြီး Token ကို Output တွင် ဖုံးကွယ်သည်။

Setup မစတင်မီ Private repository branch တစ်ခုချင်းကို Terminal credential
prompt ပိတ်ထား၍ Access စစ်သည်။ Token မှားခြင်း၊ Expire ဖြစ်ခြင်း၊ Repository
Access မရှိခြင်း သို့မဟုတ် Permission မလုံလောက်ခြင်း ဖြစ်ပါက Username/Password
တောင်းမနေဘဲ Error ဖြင့်ရပ်သင့်သည်။

အောက်ပါ URL ပုံစံများ မသုံးပါနှင့်။

```text
https://<TOKEN>@github.com/OWNER/REPOSITORY.git
https://<USERNAME>:<TOKEN>@github.com/OWNER/REPOSITORY.git
```

Token သည် Terminal, Log, Screenshot သို့မဟုတ် Git history ထဲပေါ်ခဲ့ပါက GitHub
တွင် ချက်ချင်း Revoke လုပ်ပြီး အသစ်ထုတ်ပါ။

## `setup.sh` လုပ်ဆောင်ပုံ

1. `git`, `jq`, `docker`, `python3` ရှိကြောင်း စစ်သည်။
2. `.env` ကို Safe ဖြစ်စွာ ဖတ်ပြီး Required Variables ကိုစစ်သည်။
3. `apps.json` format နှင့် Private repository access ကိုစစ်သည်။
4. မရှိသေးပါက `frappe_docker` ကို Clone လုပ်သည်။
5. Custom Apps များကို Clone/Sync လုပ်သည်။
6. `docker-compose.override.yml` ကို ပြန်ဖန်တီးသည်။
7. Custom image တွင် Apps အားလုံးပါ/မပါ စစ်ပြီး လိုအပ်မှ Build လုပ်သည်။
8. Docker Compose ကို စတင်သည်။
9. `sites/apps.txt` ကို Refresh လုပ်သည်။
10. Site မရှိသေးပါက ဖန်တီးသည်။
11. Apps များကို တစ်ခုချင်း Install လုပ်သည်။
12. `--reconfigure` ပေးထားမှ ရှိပြီးသား Site ကို Migrate လုပ်သည်။
13. Frappe Asset Cache ကို ရှင်းပြီး Installed Apps ကို ပြသည်။

## Required Environment Variables

`.env` တွင် အနည်းဆုံး အောက်ပါတန်ဖိုးများ ရှိရမည်။

```text
CUSTOM_IMAGE
FRAPPE_BRANCH
COMPOSE_FILE
SITE_DOMAIN
ADMIN_PASSWORD
MYSQL_ROOT_PASSWORD
```

`apps.json` တွင် `"private": true` ပါလျှင် `GITHUB_TOKEN` လည်း လိုသည်။

Local Database နမူနာ—

```env
CUSTOM_IMAGE=frappe-erpnext-hrms-insights:v16
FRAPPE_BRANCH=version-16
COMPOSE_FILE=pwd-with-apps.yml
SITE_DOMAIN=frontend
FRAPPE_PORT=8787
FRAPPE_INTERNAL_PORT=8080
DATABASE_MODE=local
DB_HOST=db
DB_PORT=3306
MYSQL_ROOT_PASSWORD=<strong-root-password>
MARIADB_ROOT_PASSWORD=<strong-root-password>
DB_ROOT_USERNAME=root
DB_ROOT_PASSWORD=
DB_NAME=
DB_PASSWORD=<strong-site-db-password>
ADMIN_PASSWORD=<strong-admin-password>
```

Database Variables—

- `DATABASE_MODE` — Compose MariaDB အတွက် `local`၊ သီးခြား Server အတွက်
  `external`။
- `DB_HOST` / `DB_PORT` — Frappe containers မှ ရောက်နိုင်သော Database address။
- `DB_ROOT_USERNAME` — `bench new-site` သို့ပေးမည့် MariaDB Provisioning User။
- `DB_ROOT_PASSWORD` — External Database provisioning password။ Local mode
  တွင် Blank ထားပါက `MYSQL_ROOT_PASSWORD` ကိုသုံးသည်။
- `DB_NAME` — Site အသစ်အတွက်သာဖြစ်သည်။ Blank ထားလျှင် Frappe က
  `SITE_DOMAIN` မှ name ထုတ်သည်။
- `DB_PASSWORD` — Site အသစ်၏ Database User password ဖြစ်ပြီး
  `site_config.json` တွင် သိမ်းမည်။

External Database အသစ်အတွက်
[Ubuntu VM ပေါ်ရှိ External MariaDB](../database/external-database-ubuntu.md)၊
ရှိပြီးသား Site ကိုရွှေ့ရန် [External MariaDB Migration](../database/external-database.md)
ကို ဖတ်ပါ။ `DB_HOST` ပြောင်းရုံဖြင့် Database records မရွှေ့ပါ။

## Database Credential Repair

အောက်ပါ Error သည် `sites/<site>/site_config.json` ရှိ Password နှင့် MariaDB
User password မတူကြောင်း ဆိုလိုသည်။

```text
Access denied for user '<site-db-user>'@'<container-ip>'
```

Setup သည် `list-apps` တွင် ဒီ Error ကိုတွေ့ပါက `repair_db_credentials.py` ကို
Backend container သို့ ကူးပြီး User password/grants ပြုပြင်ကာ ထပ်စမ်းသည်။
External Database အတွက် `ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=true` ကို
ရည်ရွယ်ချက်ရှိရှိ မသတ်မှတ်ထားပါက Repair ကို ပိတ်ထားသည်။

Manual Repair နမူနာ—

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml cp repair_db_credentials.py backend:/tmp/repair_db_credentials.py
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend /home/frappe/frappe-bench/env/bin/python /tmp/repair_db_credentials.py frontend
```

`frontend` ကို Site အမည်မှန်ဖြင့် ပြောင်းပါ။ Production တွင် Repair မလုပ်မီ
Verified Backup ယူပြီး target Database/User ကို စစ်ပါ။

## UI အဟောင်း သို့မဟုတ် CSS မပေါ်ခြင်း

Desk UI သည် Raw HTML ပုံစံဖြစ်နေပါက Browser က Hash အဟောင်းပါ CSS file ကို
တောင်းနေခြင်းဖြစ်နိုင်သည်။

```text
/assets/frappe/dist/css/desk.bundle.OLDHASH.css 404
```

Setup သည် Frappe `assets_json` Cache ကိုရှင်းပြီး `backend`, `frontend`,
`websocket` ကို Restart လုပ်သည်။ Setup ပြီးလည်း UI အဟောင်းမြင်ပါက Browser တွင်
Hard Refresh လုပ်ပါ။

```text
Ctrl + Shift + R
```

## Docker Credential Helper Error

Image pull လုပ်စဉ် အောက်ပါ Error ဖြစ်ပါက—

```text
error getting credentials - err: exit status 1
```

```bash
cat ~/.docker/config.json
```

WSL/Linux environment တွင် မရှိသော `desktop.exe` Credential helper ကို
ညွှန်နေခြင်း ဖြစ်နိုင်သည်။ Original file ကို Backup ယူပြီးမှ မိမိ environment
နှင့်ကိုက်ညီသော Docker credential configuration ပြင်ပါ။

```bash
cp ~/.docker/config.json ~/.docker/config.json.bak
```

Credential storage ကိုဖျက်ခြင်းမလုပ်မီ ရှိပြီးသား Registry access များအပေါ်
သက်ရောက်မှုကို စစ်ပါ။ ပြင်ပြီးလျှင် `./setup.sh` ကို ထပ် run ပါ။

## Setup စစ်ဆေးခြင်း

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml ps
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend bench --site frontend list-apps
```

`frontend` ကို `SITE_DOMAIN` အမှန်ဖြင့်ပြောင်းပြီး `apps.json` ရှိ Required Apps
အားလုံး Output တွင်ပါကြောင်း စစ်ပါ။

## မှတ်ချက်များ

- `docker-compose.override.yml` ကို `setup.sh` က Generate လုပ်သည်။ Custom App
  အတွက် Manual မထိန်းသိမ်းပါနှင့်။
- Image build သည် `docker-setup/apps.json` ကို BuildKit secret အဖြစ်သုံးသည်။
  `frappe_docker` အောက်တွင် Duplicate copy မဖန်တီးပါနှင့်။
- App install အတွင်း Patch warning ပေါ်နိုင်သည်။ Script success message,
  Installed Apps နှင့် Migration status ကို စစ်ပြီးမှ အောင်မြင်သည်ဟုယူဆပါ။
- Long-running Services များတွင် `restart: unless-stopped` သတ်မှတ်ထားသည်။
  Docker ကို Boot တွင်စတင်ရန် `sudo systemctl enable docker` သုံးနိုင်သည်။
