# Backup Automation လမ်းညွှန်

Frappe site ကို **Local Backup**, **Scheduled Backup**, **Retention** နှင့်
**Offsite Google Drive Backup** တို့ဖြင့် ကာကွယ်ရန် လမ်းညွှန်ဖြစ်သည်။

ဆက်စပ်ဖိုင်များ—

- [`backup.sh`](../../backup.sh) — Local Backup Script
- [`restore.sh`](../../restore.sh) — Backup folder မှ Restore လုပ်ရန်
- [`backup.md`](backup.md) — `backup.sh` အကျဉ်းချုပ်

## Backup အလွှာများ

| အလွှာ | Data | နေရာ | ရည်ရွယ်ချက် |
|---|---|---|---|
| 1. Live data | Docker volumes | Server | နေ့စဉ်လုပ်ငန်းသုံး Data |
| 2. Local Backup | `backup.sh` | Host ရှိ `./backups/` | Server တူတွင် မြန်မြန် Restore လုပ်ရန် |
| 3. Offsite Backup | Frappe Google Drive | Google Drive | Server ပျက်စီးလျှင် ပြန်ယူရန် |

ဖြစ်နိုင်လျှင် **3-2-1 rule** ကို လိုက်နာပါ—Data copy 3 ခု၊ Storage အမျိုးအစား
2 မျိုးနှင့် Offsite copy 1 ခုထားပါ။ Docker volume တစ်ခုတည်းကို Backup ဟု
မယူဆပါနှင့်။

## Layer 1 — Local Backup (`backup.sh`)

Script သည်—

1. Backend container ထဲတွင် `bench --site <site> backup --with-files` ကို
   run သည်။
2. SQL၊ public files၊ private files နှင့် site configuration ပါသည့် နောက်ဆုံး
   complete set ကိုစစ်ပြီး Host ရှိ
   `./backups/YYYY-MM-DD_HH-MM-SS/backups/` သို့ ကူးသည်။
3. `BACKUP_RETENTION_DAYS` ထက်ဟောင်းသော Host Backup folders များကို
   ဖယ်ရှားပြီး Container ထဲတွင် နောက်ဆုံး complete sets
   `CONTAINER_BACKUP_KEEP_COUNT` ခု ထားသည်။

`.env` configuration—

```env
BACKUP_RETENTION_DAYS=14
CONTAINER_BACKUP_KEEP_COUNT=3
```

Manual run—

```bash
cd docker-setup
chmod +x backup.sh
./backup.sh
```

နမူနာ output folder—

```text
./backups/2026-06-29_02-00-00/
```

Retention သည် Backup အသစ်အောင်မြင်ပြီး Host copy ကို စစ်ဆေးပြီးမှ run သည်။
`YYYY-MM-DD_HH-MM-SS` format မမှန်သော folder ကို ကျော်ထားပြီး Frappe Backup
တစ်ကြိမ်မှရသည့် ဖိုင်လေးခုကို complete set တစ်ခုအဖြစ် ကိုင်တွယ်သည်။

Restore လုပ်ရန် [Restore လမ်းညွှန်](restore.md) ကိုဖတ်ပါ။

```bash
./restore.sh ./backups/2026-06-29_02-00-00
```

## Layer 2 — Cron ဖြင့် နေ့စဉ် Run ခြင်း

cron သည် Linux Scheduler ဖြစ်ပြီး သတ်မှတ်ချိန်တွင် `backup.sh` ကို
အလိုအလျောက် run ပေးသည်။

### Timezone ကို အရင်စစ်ပါ

```bash
timedatectl
# or
date
```

Server timezone သည် UTC ဖြစ်ပြီး Myanmar time 02:00 (UTC+6:30) တွင် run
လိုပါက အရင်နေ့ UTC 19:30 ဖြစ်သော `30 19 * * *` ကို သုံးရမည်။ Server timezone
သည် Myanmar timezone ဖြစ်ပါက `0 2 * * *` ကို သုံးနိုင်သည်။

```text
┌─ minute (0-59)
│ ┌ hour (0-23)
│ │ ┌ day of month
│ │ │ ┌ month
│ │ │ │ ┌ day of week
│ │ │ │ │
0 2 * * *   command
```

Cron သည် shell ၏ လက်ရှိ folder ကိုမသိသောကြောင့် Script နှင့် Log အတွက်
absolute path သုံးပါ။ `<project-path>` ကို Server အမှန်၏ path ဖြင့်ပြောင်းပါ။

```bash
crontab -e
```

```cron
30 19 * * * <project-path>/docker-setup/backup.sh --yes >> <project-path>/docker-setup/backups/cron-backup.log 2>&1
```

စစ်ဆေးရန်—

```bash
crontab -l
```

Cron user သည် Docker command run နိုင်ရမည်။ Production တွင် လိုအပ်သော
permission ကို အနည်းဆုံးအတိုင်းသာပေးပါ။ WSL2 တွင် reboot ပြီးလျှင် cron
service ကို ကိုယ်တိုင်စတင်ရနိုင်သည်။

```bash
sudo service cron start
sudo service cron status
```

## Layer 3 — Google Drive Offsite Backup

ဒီနည်းသည် Frappe ၏ built-in Google Drive Backup ကို အသုံးပြုသည်။ `rclone`,
`aws-cli` သို့မဟုတ် Custom upload script မလိုပါ။ Admin Console မှ setup
လုပ်ပြီး Frappe Scheduler က Daily upload ကို စီမံပေးသည်။

### လိုအပ်ချက်များ

| လိုအပ်ချက် | မှတ်ချက် |
|---|---|
| System User | Admin Console (`/app`) ဝင်နိုင်သော Administrator |
| Scheduler | `scheduler` service run နေရမည် |
| Public HTTPS URL | `.env` ရှိ `PUBLIC_URL` နှင့်တူရမည် |
| Google account | Drive ရှိ Backup folder ပိုင်ရှင် |

Stable HTTPS Production domain ပေါ်တွင် setup လုပ်ရန် အကြံပြုသည်။

### Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com/) တွင် Project
   တစ်ခုဖန်တီးပါ။
2. **APIs & Services → Library** မှ **Google Drive API** ကို Enable လုပ်ပါ။
3. **APIs & Services → Credentials** တွင် **OAuth consent screen** ကို
   ပြင်ဆင်ပါ။
4. **Create Credentials → OAuth client ID** ကိုရွေးပြီး Application type ကို
   **Web application** သတ်မှတ်ပါ။
5. `<your-domain>` ကို မိမိ HTTPS domain ဖြင့်ပြောင်းကာ URL များထည့်ပါ။

Authorized JavaScript origin—

```text
https://<your-domain>
```

Authorized redirect URI—

```text
https://<your-domain>/api/method/frappe.integrations.google_oauth.callback
```

6. **Client ID** နှင့် **Client Secret** ကို Secret storage တွင် သိမ်းပါ။ Git
   ထဲ မထည့်ပါနှင့်။

### Frappe Admin Console

1. `https://<your-domain>/app` တွင် Login ဝင်ပါ။
2. **Google Settings** ကိုဖွင့်ပြီး **Client ID** နှင့် **Client Secret**
   ထည့်ကာ **Save** လုပ်ပါ။
3. **Google Drive** ကိုဖွင့်ပြီး **New** နှိပ်ပါ။
4. **Backup Folder Name**, **Frequency = Daily**, **Send Notification To**
   တို့ကို ဖြည့်ပါ။
5. **Save → Authorize Drive Access** နှိပ်၍ Google account ဖြင့် Allow လုပ်ပါ။
6. **Take Backup** ဖြင့် စမ်းပြီး Drive folder ထဲတွင် ဖိုင်ရောက်ကြောင်း စစ်ပါ။

Scheduler စစ်ရန်—

```bash
docker ps | grep scheduler
```

Google Drive quota ကို စောင့်ကြည့်ပါ။ Course media နှင့် file attachments များ
လာသည်နှင့် Backup size မြန်မြန်ကြီးနိုင်သည်။

## ပြဿနာဖြေရှင်းခြင်း

### `redirect_uri_mismatch`

- Google Console ရှိ Redirect URI သည် Public Site URL နှင့် အက္ခရာတိုင်း
  တိတိကျကျ တူရမည်။
- Production တွင် `https://` သုံးပါ။ မသုံးသော port မထည့်ပါနှင့်။
- **System Settings → Site URL**, Site `host_name` နှင့် `PUBLIC_URL`
  တူကြောင်း စစ်ပါ။

### Automatic Backup မလုပ်ခြင်း

- [ ] `scheduler` container run နေသည်။
- [ ] Google Drive record သည် **Authorized** ဖြစ်သည်။
- [ ] **Frequency** သတ်မှတ်ထားသည်။
- [ ] `./logs.sh` ဖြင့် Scheduler/Error Logs စစ်ပြီးဖြစ်သည်။

Manual Backup အောင်မြင်သော်လည်း Scheduled Backup မလုပ်ပါက—

```bash
docker exec -it docker-setup-backend-1 bench --site frontend doctor
```

Container နှင့် Site အမည်ကို environment အမှန်နှင့်ကိုက်ညီအောင် ပြောင်းပါ။

## Production Checklist

### Local Backup

- [ ] `backup.sh` executable ဖြစ်သည်။
- [ ] `.env` တွင် `BACKUP_RETENTION_DAYS` သတ်မှတ်ထားသည်။
- [ ] Manual `./backup.sh` အောင်မြင်သည်။
- [ ] `./backups/` အောက်တွင် Complete Backup set ရှိသည်။

### Cron

- [ ] Server timezone စစ်ပြီးဖြစ်သည်။
- [ ] Cron တွင် absolute path သုံးထားသည်။
- [ ] `cron-backup.log` သတ်မှတ်ထားသည်။
- [ ] `crontab -l` တွင် Entry တွေ့သည်။
- [ ] Cron user သည် Docker command run နိုင်သည်။

### Offsite Backup

- [ ] Google Drive API Enable လုပ်ထားသည်။
- [ ] OAuth redirect URI သည် Production domain နှင့်တူသည်။
- [ ] Google Settings သိမ်းပြီး Drive record Authorized ဖြစ်သည်။
- [ ] **Take Backup** စမ်းသပ်မှုအောင်မြင်သည်။
- [ ] Google Drive တွင် ဖိုင်ရောက်ပြီး Notification email ရသည်။
- [ ] `scheduler` container run နေသည်။

### Security နှင့် Recovery

- [ ] Default passwords မသုံးပါ။
- [ ] `PUBLIC_URL` သည် HTTPS ဖြစ်သည်။
- [ ] Google Client Secret ကို Git မထည့်ထားပါ။
- [ ] Non-production copy တွင် Restore စမ်းသပ်ပြီးဖြစ်သည်။

## ဆက်စပ်လမ်းညွှန်များ

- [Backup အကျဉ်းချုပ်](backup.md)
- [Restore လုပ်နည်း](restore.md)
- [Hosting Checklists](../setup/checklists.md)
