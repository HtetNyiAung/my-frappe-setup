# Frappe LMS Hosting Checklists

LMS ကို Domain အမှန်ဖြင့် Host မလုပ်မီ၊ လုပ်နေစဉ်နှင့် Go-Live မလုပ်မီ
အောက်ပါ Checklists များကို အသုံးပြုပါ။

## 1. Server

- [ ] Ubuntu server အဆင်သင့်ဖြစ်သည်။
- [ ] အနည်းဆုံး 2 CPU cores, 4 GB RAM (8 GB recommended), 40 GB Disk ရှိသည်။
- [ ] SSH access အလုပ်လုပ်သည်။
- [ ] Firewall တွင် HTTP/HTTPS ကို လိုအပ်သည့် source များအတွက် ဖွင့်ထားသည်။
- [ ] Docker, Docker Compose plugin, Git နှင့် `jq` install လုပ်ထားသည်။
- [ ] Reverse Proxy သုံးပါက Nginx နှင့် Certbot install လုပ်ထားသည်။

## 2. Domain နှင့် DNS

- [ ] Domain နှင့် LMS subdomain ရွေးထားသည်၊ ဥပမာ `lms.example.com`။
- [ ] DNS `A` record သည် App Server public IP ကိုညွှန်သည်။
- [ ] DNS propagation ပြီးပြီး Browser မှ Domain ရောက်နိုင်သည်။

## 3. Environment

- [ ] `.env.example` မှ `.env` ဖန်တီးထားသည်။
- [ ] `PUBLIC_URL` သည် HTTPS Domain အမှန်ဖြစ်သည်။
- [ ] `FRAPPE_PORT` မှန်သည်။
- [ ] Nginx Reverse Proxy သုံးပါက `BIND_ADDRESS=127.0.0.1` ဖြစ်သည်။
- [ ] `MYSQL_ROOT_PASSWORD`, `MARIADB_ROOT_PASSWORD`, `ADMIN_PASSWORD` နှင့်
  တခြား Secret များကို strong values ပြောင်းထားသည်။
- [ ] `SITE_DOMAIN`, `CUSTOM_IMAGE` နှင့် `apps.json` မှန်သည်။
- [ ] Local/External Database configuration ကို ရွေးပြီး network test
  အောင်မြင်သည်။

## 4. ပထမဆုံး Setup

```bash
cd docker-setup
chmod +x setup.sh deploy.sh ops.sh backup.sh restore.sh logs.sh cleanup.sh
./setup.sh
```

- [ ] Docker image build အောင်မြင်သည်။
- [ ] Frappe containers များ healthy/running ဖြစ်သည်။
- [ ] Site ဖန်တီးပြီး Required Apps install အောင်မြင်သည်။
- [ ] Migration အောင်မြင်သည်။
- [ ] Administrator Login ဝင်နိုင်သည်။

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml ps
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend bench --site frontend list-apps
```

`frontend` ကို မိမိ `SITE_DOMAIN` ဖြင့်ပြောင်းပါ။

## 5. Nginx နှင့် SSL

- [ ] Nginx Reverse Proxy config ဖန်တီးထားသည်။
- [ ] `proxy_pass` သည် Local Frappe port ကိုညွှန်သည်။
- [ ] Nginx config test နှင့် reload အောင်မြင်သည်။
- [ ] Certbot ဖြင့် SSL Certificate ထုတ်ပြီး HTTPS အလုပ်လုပ်သည်။
- [ ] HTTP မှ HTTPS သို့ Redirect ဖြစ်သည်။
- [ ] HTTPS မှ File upload စမ်းသပ်ပြီးဖြစ်သည်။

```bash
sudo certbot --nginx -d lms.example.com
```

## 6. LMS Configuration

- [ ] Branding, System Language, Timezone နှင့် Admin email မှန်သည်။
- [ ] Outbound Email ပြင်ပြီး **Send Test Email** အောင်မြင်သည်။
- [ ] Login page မှ Forgot Password email စမ်းပြီးဖြစ်သည်။
- [ ] Instructor နှင့် Learner accounts များဖန်တီးထားသည်။
- [ ] Course, Lesson, Program နှင့် Enrollment workflow စမ်းပြီးဖြစ်သည်။
- [ ] Progress tracking နှင့် Certificate စမ်းပြီးဖြစ်သည်။
- [ ] Learner Role ဖြင့် Permission စမ်းပြီးဖြစ်သည်။

Email အတွက် [Outlook/Email Setup လမ်းညွှန်](../integrations/email-outlook-setup-guide.md)
ကို ကြည့်ပါ။

## 7. PDF နှင့် Attachments

- [ ] PDF ကို Attachment အဖြစ် Upload လုပ်ထားသည်။
- [ ] Learner မြင်ရမည့် Content တွင် မှန်ကန်သော Link ထည့်ထားသည်။
- [ ] Learner account ဖြင့် PDF ဖွင့်/Download စမ်းပြီးဖြစ်သည်။
- [ ] Private file Permission နှင့် Public file access ကို သီးခြားစမ်းထားသည်။
- [ ] File name သည် ဖတ်ရှုရလွယ်ကူသည်။

## 8. Backup နှင့် Restore

- [ ] `./backup.sh` အောင်မြင်ပြီး Database/public/private files ရှိသည်။
- [ ] `.env` တွင် `BACKUP_RETENTION_DAYS` သတ်မှတ်ထားသည်။
- [ ] Scheduled Backup သုံးပါက cron run နှင့် Logs ကိုစစ်ပြီးဖြစ်သည်။
- [ ] Offsite Backup သို့မဟုတ် Server ပြင်ပ copy ရှိသည်။
- [ ] Test Server ပေါ်တွင် Restore စမ်းသပ်ပြီးဖြစ်သည်။

```bash
cd docker-setup
./backup.sh
```

အသေးစိတ်ကို [Backup Automation လမ်းညွှန်](../operations/backup-automation-guide.md)
တွင် ဖတ်ပါ။

## 9. Maintenance

- [ ] Container health နှင့် Disk usage ကို အပတ်စဉ်စစ်သည်။
- [ ] User error တင်ပြလာလျှင် Logs စစ်သည်။
- [ ] Update မတိုင်မီ Verified Backup ရှိသည်။
- [ ] Update ပြီးလျှင် Login, Course, Lesson, PDF နှင့် Background jobs စမ်းသည်။

```bash
cd docker-setup
./ops.sh status
./ops.sh logs
./deploy.sh check
./deploy.sh plan
./deploy.sh apply
```

`cleanup.sh` သည် Data volumes ကိုဖျက်နိုင်သော destructive Script ဖြစ်သောကြောင့်
Maintenance command အဖြစ် မသုံးပါနှင့်။

## 10. Go-Live

- [ ] HTTPS Domain အလုပ်လုပ်သည်။
- [ ] Default password/Secret မရှိတော့ပါ။
- [ ] Test Administrator, Instructor နှင့် Learner accounts အလုပ်လုပ်သည်။
- [ ] Course access, Enrollment, Progress, Certificate နှင့် PDF Download
  အလုပ်လုပ်သည်။
- [ ] Outbound Email နှင့် Password Reset အလုပ်လုပ်သည်။
- [ ] Verified Local/Offsite Backup ရှိပြီး Restore procedure ကို Operator
  နားလည်သည်။
- [ ] Monitoring နှင့် Support contact သတ်မှတ်ထားသည်။
