# Application Deployment လမ်းညွှန်

`setup.sh` ဖြင့် Site ဖန်တီးပြီးနောက် ပုံမှန် Code Release အတွက် `deploy.sh`
ကို အသုံးပြုပါ။ Command အားလုံးကို `docker-setup/` မှ run ပါ။

## Commands

| Command | State ပြောင်းမလား | ရည်ရွယ်ချက် |
|---|---:|---|
| `./deploy.sh check` | မပြောင်းပါ | `.env`, `apps.json`, Git access, Compose, Services, Site နှင့် Database access စစ်သည်။ |
| `./deploy.sh plan` | မပြောင်းပါ | Remote Branch/Tag revisions နှင့် Deployment sequence ပြသည်။ |
| `./deploy.sh apply` | ပြောင်းသည် | Build, Backup, Deploy, Migrate, Cache clear, Restart နှင့် Verify လုပ်သည်။ |
| `./deploy.sh verify` | မပြောင်းပါ | Services, Site availability နှင့် Database access စစ်သည်။ |

အကြံပြုအစဉ်—

```bash
./deploy.sh check
./deploy.sh plan
./deploy.sh apply
./deploy.sh verify
```

`apply` တွင် `DEPLOY` ဟု အတည်ပြုရသည်။ ယုံကြည်ရသော CI/Automation အတွက်—

```bash
./deploy.sh apply --yes
```

## `apply` လုပ်ဆောင်ပုံ

1. Docker, Compose, Existing Site, Database access နှင့် Git Branch/Tag
   တစ်ခုချင်းကို စစ်သည်။
2. `apps.json` entry တစ်ခုချင်း၏ Remote Commit ကို မှတ်တမ်းတင်သည်။
3. လက်ရှိ Containers များကို run ထားစဉ် Candidate image ကို Build လုပ်သည်။
4. Maintenance Mode ဖွင့်ပြီး Scheduler/Queue Workers ကို ရပ်သည်။
5. `backup.sh --yes` run သည်။ Verified Backup မအောင်မြင်ပါက ရပ်သည်။
6. Host-mounted Custom Apps များကို သတ်မှတ် Branch နှင့် Sync လုပ်သည်။
7. Previous image ကို timestamp ပါ `-rollback-...` Tag ဖြင့်ထားပြီး Candidate
   ကို `CUSTOM_IMAGE` အဖြစ် သတ်မှတ်သည်။
8. Application Services ပြန်ဖန်တီး၍ App အသစ် Install လုပ်ပြီး `bench migrate`
   ကို တစ်ကြိမ်သာ run သည်။
9. Site/Website Cache ရှင်းပြီး ကျန် Services များကို ပြန်ဖန်တီးသည်။
10. Services နှင့် Database connection အောင်မြင်မှ Maintenance Mode ပိတ်သည်။
11. Source revisions ကို `logs/releases/` အောက်တွင် မှတ်တမ်းတင်သည်။

## မအောင်မြင်သည့်အခါ

- Git access/Image build failure သည် Maintenance Mode မဖွင့်မီဖြစ်၍ Running
  Containers မပြောင်းပါ။
- Backup failure ဖြစ်ပါက New image မဖွင့်မီ ရပ်သည်။
- Sync, Service, Migration သို့မဟုတ် Verification failure ဖြစ်ပါက Maintenance
  Mode ဖွင့်ထားနိုင်ပြီး Writers များလည်း ရပ်နေနိုင်သည်။
- Migration စပြီးနောက် Database ကို အလိုအလျောက် Restore မလုပ်ပါ။ Schema
  Rollback သည် Matching Code image နှင့် Verified Backup ကိုအခြေခံသည့်
  ရည်ရွယ်ချက်ရှိသော Recovery decision ဖြစ်ရမည်။

```bash
./ops.sh status
./ops.sh logs backend
./ops.sh logs scheduler
```

ပြဿနာပြင်ပြီး Verification အောင်မြင်မှ—

```bash
./ops.sh maintenance-off
```

Previous image ပြန်သုံးရန် Timestamped Rollback Tag ကိုအရင်စစ်ပြီး Code/Database
compatibility သေချာမှသာ Retag/Recreate လုပ်ပါ။ Host-mounted Apps များကိုလည်း
မှတ်တမ်းရှိ Commit များသို့ ပြန်ထားရမည်။

```bash
docker image ls
docker tag <rollback-image-tag> <CUSTOM_IMAGE>
docker compose -f <COMPOSE_FILE> -f docker-compose.override.yml up -d \
  --no-deps --force-recreate \
  backend websocket frontend queue-long queue-short scheduler
./ops.sh status
```

## Private GitHub Apps

`apps.json` တွင် Clean repository URL နှင့် `"private": true` သုံးပြီး
Fine-grained read-only token ကို Git က ignore လုပ်ထားသော `.env` ရှိ
`GITHUB_TOKEN` တွင်သာ သိမ်းပါ။ Script သည် Interactive credential prompt ကို
ပိတ်ပြီး Access စစ်ခြင်း၊ Build output မှ Token ဖုံးကွယ်ခြင်းနှင့် Temporary
authenticated file ဖျက်ခြင်းတို့ကို လုပ်သည်။

## လုပ်ဆောင်ချက်နယ်ပယ်

- `deploy.sh` သည် Existing Site ကို Code Deploy လုပ်သည်။ Site အသစ်မဖန်တီးပါ။
- `setup.sh` သည် First Installation/Explicit Infrastructure Reconfiguration
  အတွက်ဖြစ်သည်။
- `production.sh` သည် Production security/runtime settings ကို apply လုပ်ပြီး
  ပုံမှန် Release command မဟုတ်ပါ။
- `backup.sh` နှင့် `restore.sh` သည် သီးခြား Data-management tools ဖြစ်သည်။
