# Restore Script (`restore.sh`)

`restore.sh` သည် `.env` တွင် သတ်မှတ်ထားသော Frappe site ထဲသို့ Backup
ပြန်သွင်းပေးသည်။ Restore သည် လက်ရှိ data ကို overwrite လုပ်သော destructive
operation ဖြစ်ကြောင်း နားလည်ပြီးမှ Production တွင် အသုံးပြုပါ။

## Restore လုပ်ပေးသည့်ဖိုင်များ

- Database Backup: `*database.sql.gz`
- Public files Backup: `*files.tar`
- Private files Backup: `*private-files.tar`

Script သည် ပေးထားသော folder အောက်တွင် ဖိုင်များကိုရှာသောကြောင့် အောက်ပါ path
နှစ်မျိုးစလုံး အသုံးပြုနိုင်သည်။

```bash
./restore.sh ./backups/2026-05-14_06-37-00
./restore.sh ./backups/2026-05-14_06-37-00/backups
```

## Script လုပ်ဆောင်ပုံ

1. `docker-setup` folder ထဲမှ `.env` ကို ဖတ်သည်။
2. `BACKEND_CONTAINER` နှင့် `SITE_DOMAIN` ရှိကြောင်း စစ်သည်။
3. Backend container run နေကြောင်း စစ်သည်။
4. Database၊ public files နှင့် private files Backup archive များကို ရှာသည်။
5. `--yes` မပါလျှင် User ထံမှ အတည်ပြုချက်တောင်းသည်။
6. `--skip-pre-backup` မပါလျှင် Restore မတိုင်မီ safety Backup ဖန်တီးသည်။
7. Backup files များကို Container အတွင်း Temporary storage သို့ ကူးသည်။
8. Public/private file flags များဖြင့် `bench restore` ကို run သည်။
9. `bench migrate` ကို run သည်။
10. Frappe cache နှင့် website cache ကို ရှင်းသည်။
11. Container အတွင်း Temporary restore files ကို ဖယ်ရှားသည်။

## အသုံးပြုပုံ

Interactive Production Restore—

```bash
cd docker-setup
./restore.sh ./backups/2026-05-14_06-37-00/backups
```

Non-interactive Restore—

```bash
cd docker-setup
./restore.sh --yes ./backups/2026-05-14_06-37-00/backups
```

Pre-restore Backup မလုပ်ဘဲ Restore—

```bash
cd docker-setup
./restore.sh --skip-pre-backup ./backups/2026-05-14_06-37-00/backups
```

`--skip-pre-backup` ကို လက်ရှိ Site ပျက်နေပြီး Backup လုံးဝမလုပ်နိုင်သည့်အခါမှ
သုံးပါ။

## အရေးကြီးသတိပေးချက်

ဒီ Script သည် destructive ဖြစ်ပြီး `.env` ရှိ `SITE_DOMAIN` ၏ လက်ရှိ
Database ကို overwrite လုပ်မည်။ Production Restore မလုပ်မီ—

- Server မှန်ကြောင်း စစ်ပါ။
- `.env` က target Site မှန်ကိုညွှန်ကြောင်း စစ်ပါ။
- Backup folder သည် Restore လုပ်မည့် Site မှရလာကြောင်း စစ်ပါ။
- Database၊ public files နှင့် private files သုံးမျိုးလုံး ပါကြောင်း စစ်ပါ။
- Restore နှင့် safety Backup အတွက် Disk space လုံလောက်ကြောင်း စစ်ပါ။

## လိုအပ်ချက်များ

- Frappe containers များ run နေရမည်။
- `.env` ရှိ `BACKEND_CONTAINER` မှန်ရမည်။
- `.env` ရှိ `SITE_DOMAIN` သည် target Site နှင့်ကိုက်ညီရမည်။
- Backup folder တွင် `*database.sql.gz` ရှိရမည်။

## Backup Folder နမူနာ

```text
20260514_130702-frontend-database.sql.gz
20260514_130702-frontend-files.tar
20260514_130702-frontend-private-files.tar
20260514_130702-frontend-site_config_backup.json
```

`site_config_backup.json` ကို ရည်ညွှန်းရန်သာ သိမ်းထားသည်။ Target server ၏
Database credentials ပျက်သွားနိုင်သောကြောင့် Script က လက်ရှိ
`site_config.json` ကို အလိုအလျောက် overwrite မလုပ်ပါ။
