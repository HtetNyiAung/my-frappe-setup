# Backup Script (`backup.sh`)

> **အသေးစိတ်လမ်းညွှန်:** [Backup Automation လမ်းညွှန်](backup-automation-guide.md) တွင် local Backup၊ cron schedule၊ retention နှင့် Google Drive offsite setup ကို ဖတ်ပါ။

`backup.sh` သည် Production environment အတွက် အရေးကြီးသော utility ဖြစ်သည်။
၎င်းသည် Frappe container အတွင်း Backup ဖန်တီးပြီး သိမ်းဆည်းရန် host machine
သို့ ကူးယူပေးသည်။

## ဘာတွေလုပ်ပေးသလဲ

1. **Bench Backup** — Frappe backend container ထဲတွင်
   `bench backup --with-files` ကို run ပြီး အောက်ပါတို့ကို ဖန်တီးသည်။
   - Database SQL dump
   - Public files နှင့် private files archive
2. **Verification နှင့် host သို့ကူးယူခြင်း** — နောက်ဆုံးပြည့်စုံသော Backup set
   ကိုရှာပြီး Database၊ public files၊ private files နှင့် site configuration
   files ရှိကြောင်း စစ်ဆေးကာ ထို set ကိုသာ host သို့ ကူးသည်။
3. **Timestamp** — `./backups/` အောက်တွင် `YYYY-MM-DD_HH-MM-SS` အမည်ဖြင့်
   folder ခွဲသိမ်းသည်။
4. **Retention** — Host copy မှန်ကန်ကြောင်းစစ်ပြီးနောက်
   `BACKUP_RETENTION_DAYS` (default `14`) ထက်ဟောင်းသော host Backup များကို
   ဖျက်သည်။ Container အတွင်း နောက်ဆုံးပြည့်စုံသော set
   `CONTAINER_BACKUP_KEEP_COUNT` (default `3`) ခုကို ထိန်းသိမ်းသည်။
5. **Optional S3 Upload** — `S3_STORAGE_ENABLED=true` နှင့်
   `S3_BACKUP_UPLOAD_ENABLED=true` နှစ်ခုစလုံးဖြစ်ပါက private S3 Backup Bucket
   သို့ upload လုပ်ပြီး object တစ်ခုချင်း၏ size ကို စစ်ဆေးသည်။

`.env` တွင် retention ကို သတ်မှတ်ပါ။

```env
BACKUP_RETENTION_DAYS=14
CONTAINER_BACKUP_KEEP_COUNT=3
```

S3 Backup upload ကို `.env` တွင် သတ်မှတ်ပါ။

```env
S3_STORAGE_ENABLED=true
S3_BACKUP_UPLOAD_ENABLED=true
S3_BACKUP_BUCKET_NAME=app-backups
S3_BACKUP_PREFIX=frappe-backups
S3_BACKUP_RETENTION_DAYS=30
```

Backup အတွက် သီးခြား private Bucket ကိုသာ သုံးပါ။ Database Backup ကို public
Bucket သို့မဟုတ် attachment Bucket ထဲ မသိမ်းပါနှင့်။

## အသုံးပြုပုံ

```bash
chmod +x backup.sh
./backup.sh
```

Manual run တွင် target site ကိုပြပြီး Backup မစတင်မီ `BACKUP` ဟု
အတည်ပြုခိုင်းသည်။ cron ကဲ့သို့ ယုံကြည်ရသော non-interactive Automation အတွက်—

```bash
./backup.sh --yes
```

## Backup သိမ်းသည့်နေရာ

```text
./docker-setup/backups/[TIMESTAMP]/
```

## ဘာကြောင့်လိုအပ်သလဲ

Docker volume သည် Backup အစားထိုးမဟုတ်ပါ။ ဒီ Script ဖြင့် ရရှိသော Database
dump နှင့် file archive များကို—

- Offsite storage (S3, Google Drive စသည်) သို့ ရွှေ့နိုင်သည်။
- `restore.sh` ဖြင့် တခြား server တွင် Site ပြန်တင်နိုင်သည်။
- ရေရှည် data protection အတွက် version ခွဲသိမ်းနိုင်သည်။
