# Frappe Setup နှင့် Operations Script အသုံးပြုနည်း

ဒီ guide က ဘယ်အခြေအနေမှာ ဘယ် script ကို run ရမလဲ ရွေးချယ်နိုင်ရန်
ရေးထားတာဖြစ်ပါတယ်။ ရှင်းလင်းမှုရှိစေရန် Technical Term နဲ့ command အမည်တွေကို
English အတိုင်းထားပါတယ်။

## အရင်ဆုံးသိထားရမည့်အချက်

Command အားလုံးကို `docker-setup/` folder ထဲကနေ run ပါ။

```bash
cd /path/to/my-frappe-setup/docker-setup
```

အသုံးပြုမည့် script တစ်ခုချင်းစီရဲ့ တာဝန်က သီးခြားဖြစ်ပါတယ်။

- `setup.sh` — First Setup သို့မဟုတ် Infrastructure Reconfiguration
- `deploy.sh` — Existing site အတွက် routine Code Deployment
- `ops.sh` — Status, Logs, Restart, Cache နဲ့ controlled Migration
- `backup.sh` — Backup အသစ်ယူရန်
- `restore.sh` — Backup ပြန်သွင်းရန်
- `production.sh` — Production readiness နဲ့ Production settings
- `update.sh` — အဟောင်း compatibility အတွက်သာဖြစ်ပြီး `deploy.sh apply` ကို
  ခေါ်ပေးပါတယ်

## ဘာလုပ်ချင်ရင် ဘာ run ရမလဲ

| လုပ်ဆောင်လိုသည့်အရာ | အသုံးပြုရမည့် command |
|---|---|
| Site အသစ် စတင်ဆောက်ခြင်း | `./setup.sh` |
| `.env`, Database, S3 သို့မဟုတ် generated Compose configuration ပြောင်းခြင်း | `./setup.sh --reconfigure` |
| Reconfiguration အတွင်း image အသစ်ပြန်ဆောက်ခြင်း | `./setup.sh --reconfigure --rebuild` |
| Code update မလုပ်မီ Preflight စစ်ခြင်း | `./deploy.sh check` |
| Deploy မည့် Git branch/tag နဲ့ commit ကြည့်ခြင်း | `./deploy.sh plan` |
| ပုံမှန် Code Deployment | `./deploy.sh apply` |
| Deployment ပြီးနောက် အခြေအနေစစ်ခြင်း | `./deploy.sh verify` |
| Containers, Site နဲ့ Database status စစ်ခြင်း | `./ops.sh status` |
| Site Cache ရှင်းခြင်း | `./ops.sh clear-cache` |
| Frappe services Restart လုပ်ခြင်း | `./ops.sh restart` |
| Code မပြောင်းဘဲ Migration သီးသန့်လုပ်ခြင်း | `./ops.sh migrate` |
| Backend Logs ကြည့်ခြင်း | `./ops.sh logs backend` |
| Backend Logs ကို ဆက်တိုက်ကြည့်ခြင်း | `./ops.sh logs backend --follow` |
| Backup ယူခြင်း | `./backup.sh` |
| Backup ပြန်သွင်းခြင်း | `./restore.sh <backup-folder>` |
| Production readiness စစ်ခြင်း | `./production.sh check` |
| Production settings လုပ်ခြင်း | `./production.sh apply` |
| Production settings ပြန်စစ်ခြင်း | `./production.sh verify` |

## 1. First Setup

Server အသစ်မှာ Site မရှိသေးသောအချိန်မှသာ `setup.sh` ကို normal run ပါ။

### Step 1: Configuration files ပြင်ဆင်ခြင်း

```bash
cp .env.example .env
cp apps.json.example apps.json
```

ပြီးနောက် `.env` နဲ့ `apps.json` ကို environment အလိုက်ပြင်ပါ။ Private GitHub
repository ပါပါက clean repository URL သုံးပြီး `.env` ထဲမှာသာ
`GITHUB_TOKEN` ထည့်ပါ။

### Step 2: First Setup run ခြင်း

```bash
./setup.sh
```

Prompt ပြလာသောအခါ target Site, Database နဲ့ image အချက်အလက်တွေ မှန်ကြောင်း
စစ်ပြီး `SETUP` လို့ရိုက်ပါ။ Script က image build, Containers start, Site create,
App install, Migration နဲ့ Cache clear ကိုလုပ်ပေးပါတယ်။

### Step 3: Setup ပြီးကြောင်းစစ်ခြင်း

```bash
./ops.sh status
```

Services, Site နဲ့ Database connection အားလုံး `[PASS]` ဖြစ်ရပါမယ်။

> Existing site ရှိပြီးသားမှာ `./setup.sh` ကို routine update အတွက် မသုံးပါနှင့်။
> Script က existing site ကိုတွေ့ပါက ရပ်ပြီး `deploy.sh` သုံးရန်ပြောပါမယ်။

## 2. ပုံမှန် Code Deployment

Application code သို့မဟုတ် `apps.json` ထဲက branch/tag ပြောင်းထားပြီး Existing
site ကို update လုပ်လိုပါက အောက်ပါအစီအစဉ်အတိုင်း run ပါ။

### Step 1: Preflight

```bash
./deploy.sh check
```

ဒီ command က state မပြောင်းပါ။ Docker, Compose, Site, Database connection,
Services နဲ့ Git repository access ကို စစ်ပေးပါတယ်။ Fail ဖြစ်ပါက `apply` ကို
မလုပ်သေးဘဲ error ကိုအရင်ဖြေရှင်းပါ။

### Step 2: Deployment Plan ကြည့်ခြင်း

```bash
./deploy.sh plan
```

Deploy မည့် app တစ်ခုချင်းစီရဲ့ branch/tag နဲ့ observed commit ကိုစစ်ပါ။ မျှော်မှန်း
ထားသည့် version မဟုတ်ပါက `apps.json` ကိုအရင်ပြင်ပါ။

### Step 3: Deployment လုပ်ခြင်း

```bash
./deploy.sh apply
```

အတည်ပြုရန် `DEPLOY` လို့ရိုက်ရပါမယ်။ `apply` က အောက်ပါတို့ကိုအစဉ်လိုက်
လုပ်ပေးပါတယ်။

1. Candidate image ကို build လုပ်ခြင်း
2. Maintenance Mode ဖွင့်ခြင်း
3. Scheduler နဲ့ Queue Workers ရပ်ခြင်း
4. Verified Backup ယူခြင်း
5. Custom App code sync လုပ်ခြင်း
6. Frappe services recreate လုပ်ခြင်း
7. App အသစ်ရှိပါက install လုပ်ခြင်း
8. `bench migrate` run ခြင်း
9. Cache clear လုပ်ခြင်း
10. Services နဲ့ Database connection Verify လုပ်ခြင်း
11. အားလုံးအောင်မြင်မှ Maintenance Mode ပိတ်ခြင်း

### Step 4: နောက်ဆုံး Verification

```bash
./deploy.sh verify
```

ပြီးနောက် Browser မှာ Login, အဓိက Module, File upload/download နဲ့ Background
Jobs တွေကို functional test လုပ်ပါ။

## 3. `.env` သို့မဟုတ် Infrastructure ပြောင်းခြင်း

အောက်ပါပြောင်းလဲမှုတွေမှာ `deploy.sh` မဟုတ်ဘဲ explicit Reconfiguration သုံးပါ။

- Local Database မှ External Database သို့ပြောင်းခြင်း
- `DB_HOST`, `DB_PORT` သို့မဟုတ် Storage configuration ပြောင်းခြင်း
- S3/MinIO configuration ပြောင်းခြင်း
- Custom App volume mounts ပြန် generate လုပ်ရန်လိုခြင်း
- Setup ကထိန်းချုပ်သည့် Public URL သို့မဟုတ် Branding ပြောင်းခြင်း

```bash
./setup.sh --reconfigure
```

Image အသစ်ပါပြန်ဆောက်ရန်လိုလျှင်:

```bash
./setup.sh --reconfigure --rebuild
```

Database server ပြောင်းခြင်းက data ကို အလိုအလျောက် copy မလုပ်ပါ။ Existing Site
Migration ဖြစ်ပါက [External Database Migration Guide](../database/external-database.md)
ကိုလိုက်နာပြီး Maintenance Window နဲ့ verified Backup ထားရပါမယ်။

## 4. Migration သီးသန့်လုပ်ခြင်း

Code က container ထဲရောက်ပြီးသားဖြစ်သော်လည်း Database schema update လုပ်ရန်သာ
လိုပါက:

```bash
./ops.sh migrate
```

Prompt မှာ `MIGRATE` လို့ရိုက်ပါ။ ဒီ command က deployment lock ယူပြီး
Maintenance Mode, Workers stop, Backup, Migration, Cache clear, Restart နဲ့
Verification ကို ထိန်းချုပ်လုပ်ပေးပါတယ်။

Routine Code Deployment မှာ `deploy.sh apply` က Migration ပါလုပ်ပြီးသားဖြစ်လို့
နောက်ထပ် `ops.sh migrate` ထပ် run ရန်မလိုပါ။

## 5. Cache နှင့် Restart

Code မပြောင်းဘဲ အဟောင်း UI, translation သို့မဟုတ် cached page မြင်နေရပါက:

```bash
./ops.sh clear-cache
```

Browser မှာလည်း Hard Refresh လုပ်ပါ။

```text
Ctrl + Shift + R
```

Services ပုံမှန် Restart လုပ်ရန်:

```bash
./ops.sh restart
```

Prompt မှာ `RESTART` လို့ရိုက်ပါ။ Restart တစ်ခုတည်းလိုသောအခြေအနေမှာ
`setup.sh` သို့မဟုတ် `deploy.sh apply` မ run ပါနှင့်။

## 6. Status နှင့် Logs

အခြေအနေစစ်ရန်:

```bash
./ops.sh status
```

Backend ရဲ့ နောက်ဆုံး Logs ကြည့်ရန်:

```bash
./ops.sh logs backend --tail 200
```

Logs ကို live ကြည့်ရန်:

```bash
./ops.sh logs backend --follow
```

Queue သို့မဟုတ် Scheduler ပြဿနာရှိပါက:

```bash
./ops.sh logs queue-short --tail 200
./ops.sh logs queue-long --tail 200
./ops.sh logs scheduler --tail 200
```

## 7. Backup နှင့် Restore

Manual Backup ယူရန်:

```bash
./backup.sh
```

Prompt မှာ `BACKUP` လို့ရိုက်ပါ။ Database dump, Public Files, Private Files နဲ့
Site configuration backup အားလုံး non-empty ဖြစ်ကြောင်း script က Verify
လုပ်ပေးပါတယ်။

Restore က data ကိုပြောင်းလဲသော operation ဖြစ်တဲ့အတွက် target Site နဲ့ Backup
folder ကို သေချာစစ်ပြီးမှ run ပါ။

```bash
./restore.sh /path/to/backup-folder
```

Production data ကို Restore မလုပ်မီ
[Restore Guide](../operations/restore.md) ကိုဖတ်ပါ။

## 8. Production စတင်ခြင်း

Production configuration ကို အရင် read-only စစ်ပါ။

```bash
./production.sh check
```

Issues အားလုံးပြင်ပြီး approved Maintenance Window အတွင်းမှသာ:

```bash
./production.sh apply
./production.sh verify
```

`production.sh` က Production settings အတွက်ဖြစ်ပါတယ်။ Routine Code Deployment
အစားထိုး command မဟုတ်ပါ။ Production အတွက် code update လုပ်တိုင်း
`deploy.sh check`, `plan`, `apply`, `verify` workflow ကိုသုံးပါ။

## 9. Deployment Fail ဖြစ်လျှင်

Candidate image build မအောင်မြင်ပါက running Containers ကို မပြောင်းသေးပါ။
Maintenance Mode ဝင်ပြီးနောက် Backup, Migration သို့မဟုတ် Verification fail
ဖြစ်ပါက Site ကို Maintenance Mode အတိုင်းထားပါတယ်။ Database ကို
အလိုအလျောက် Restore မလုပ်ပါ။

အရင်ဆုံးစစ်ရန်:

```bash
./ops.sh status
./ops.sh logs backend --tail 200
./ops.sh logs scheduler --tail 200
```

ပြဿနာကိုပြင်ပြီး Site နဲ့ Database ကို Verify လုပ်ပြီးမှ Maintenance Mode ပိတ်ပါ။

```bash
./ops.sh maintenance-off
```

Prompt မှာ `RECOVERED` လို့ရိုက်ပါ။ Database Migration စပြီးနောက် Code image
တစ်ခုတည်းကို အဟောင်းပြန်ပြောင်းခြင်းက schema mismatch ဖြစ်နိုင်ပါတယ်။ Rollback
မလုပ်မီ Code version, Database schema နဲ့ Backup ကိုအတူတူစစ်ရပါမယ်။

## 10. မသုံးသင့်သောပုံစံများ

- Routine update တိုင်း `./setup.sh` မ run ပါနှင့်။
- `deploy.sh apply` ပြီးတိုင်း Migration ထပ်မ run ပါနှင့်။
- Backup failure ကိုကျော်ပြီး Deployment ဆက်မလုပ်ပါနှင့်။
- Migration failure ဖြစ်နေစဉ် Maintenance Mode ကိုချက်ချင်းမပိတ်ပါနှင့်။
- Token ကို `apps.json`, Git URL, command history သို့မဟုတ် documentation ထဲ
  မထည့်ပါနှင့်။
- Production မှာ real IP, Password သို့မဟုတ် Token ကို log/screenshot နဲ့
  မမျှဝေပါနှင့်။
- Database data, Docker volume သို့မဟုတ် Backup ကို troubleshooting shortcut
  အဖြစ် မဖျက်ပါနှင့်။

## အမြန်ရွေးချယ်ရန်

```text
Site အသစ်လား?
  └─ ဟုတ် → ./setup.sh

Existing site မှာ Infrastructure ပြောင်းမလား?
  └─ ဟုတ် → ./setup.sh --reconfigure

Code update လုပ်မလား?
  └─ ဟုတ် → deploy.sh check → plan → apply → verify

Code မပြောင်းဘဲ Migration လုပ်မလား?
  └─ ဟုတ် → ./ops.sh migrate

Cache, Restart, Status သို့မဟုတ် Logs ပဲလိုသလား?
  └─ ဟုတ် → သက်ဆိုင်ရာ ./ops.sh command ကိုသုံးပါ
```

အသေးစိတ်အချက်အလက်များအတွက် [Documentation Index](../README.md) ကိုကြည့်ပါ။
