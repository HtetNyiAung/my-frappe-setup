# Production Launch Checklist

ဒီ Checklist ကို Frappe Site ကို User အမှန်များအတွက် Go-Live မလုပ်မီ
System Administrator, Deployment Engineer နှင့် Application Administrator
တို့က အတူစစ်ရန် အသုံးပြုပါ။ Automated အပိုင်းများ—

```bash
./production.sh check
./production.sh apply
./production.sh verify
```

`apply` သည် Settings မပြောင်းမီ Verified Backup ဖန်တီးသော်လည်း Manual DNS,
TLS, Reverse Proxy, Access Control နှင့် Restore Test များကို အစားမထိုးပါ။

## 1. Launch Decision

- [ ] Approved Production Server နှင့် Launch date မှန်သည်။
- [ ] Support window နှင့် Emergency Rollback အတည်ပြုသူ သတ်မှတ်ထားသည်။
- [ ] Staging/Test Data နှင့် Production Data သီးခြားဖြစ်သည်။
- [ ] Test-only Data ကို Production User မမြင်ပါ။
- [ ] Application owner က Launch scope ကို လက်ခံထားသည်။

```text
Internal Test -> Limited User Rollout -> Full Production Rollout
```

## 2. Domain နှင့် HTTPS

- [ ] DNS သည် Production Server ကိုညွှန်သည်။
- [ ] HTTPS Certificate နှင့် Reverse Proxy ပြင်ပြီးဖြစ်သည်။
- [ ] HTTP မှ HTTPS Redirect ဖြစ်သည်။
- [ ] Frappe `host_name` သည် Public URL အမှန်ဖြစ်သည်။

```env
DEPLOYMENT_MODE=production
REQUIRE_PRODUCTION_READY=1
SITE_DOMAIN=frontend
PUBLIC_URL=https://app.example.com
FRAPPE_PORT=8787
FRAPPE_INTERNAL_PORT=8080
BIND_ADDRESS=127.0.0.1
```

`8080`/`8787` ကို User များထံ တိုက်ရိုက်မဖွင့်ပါနှင့်။
[Reverse Proxy လမ်းညွှန်](reverse-proxy-guide.md) ကိုကြည့်ပါ။

## 3. Docker Compose

- [ ] `CUSTOM_IMAGE`, `FRAPPE_SITE_NAME_HEADER` နှင့် Named Volumes မှန်သည်။
- [ ] Long-running Services တွင် `restart: unless-stopped` ရှိသည်။
- [ ] Database, Redis, Backend, Frontend, WebSocket Health Checks ရှိသည်။
- [ ] Log rotation နှင့် Server size နှင့်ကိုက်သော Memory limits ရှိသည်။
- [ ] Frontend သည် Intended Host port သာ expose လုပ်သည်။
- [ ] Database port Public မဖွင့်ထားပါ။

Local-only Database Client access လိုမှ—

```yaml
ports:
  - "127.0.0.1:3307:3306"
```

Direct Database Client access မလိုပါက DB `ports` section ကို မထားပါနှင့်။

## 4. Secrets နှင့် Passwords

- [ ] `.env` ကို Git မထည့်ထားပါ။
- [ ] `ADMIN_PASSWORD`, Database passwords နှင့် Optional Service passwords
  များသည် Default မဟုတ်ဘဲ Strong ဖြစ်သည်။
- [ ] Secret keys ကို Random value ဖြင့်ထုတ်ထားသည်။
- [ ] Git URLs, Logs နှင့် Documentation တွင် Token/Secret မရှိပါ။

```bash
openssl rand -base64 32
```

## 5. Git နှင့် App Sources

- [ ] `apps.json` တွင် Approved Apps/Branches/Tags သာရှိသည်။
- [ ] Custom App source ကို Version Control လုပ်ထားသည်။
- [ ] Production တွင် Staging စမ်းပြီးသော Commit/Tag/Release Branch သုံးသည်။
- [ ] Private Apps တွင် Fine-grained Token/Deploy Key ကို Securely သုံးသည်။
- [ ] Token ကို URL သို့မဟုတ် Git history ထဲ မထည့်ထားပါ။

## 6. Launch မတိုင်မီ Backup

- [ ] Manual Backup အောင်မြင်သည်။
- [ ] Database, Public files, Private files နှင့် Site config ပါသည်။
- [ ] Server ပြင်ပတွင် Verified copy ရှိသည်။
- [ ] Non-production Server တွင် Restore Test လုပ်ပြီးဖြစ်သည်။

```bash
cd <project-path>/docker-setup
./backup.sh
```

```env
AUTO_BACKUP_BEFORE_SETUP=1
REQUIRE_BACKUP_BEFORE_SETUP=1
```

## 7. Restore Test

- [ ] Restore procedure မှတ်တမ်းတင်ထားသည်။
- [ ] Backup အမှန်ဖြင့် Restore အောင်မြင်သည်။
- [ ] Restore ပြီး Admin Login, Files, Core pages နှင့် Background jobs
  အလုပ်လုပ်သည်။

Restore စမ်းမထားသော Backup ကို Recovery-ready ဟု မယူဆပါနှင့်။

## 8. Database Access

- [ ] Database port Public မဖွင့်ဘဲ Trusted sources အတွက်သာ Allow လုပ်ထားသည်။
- [ ] Site Database credentials ကို Securely သိမ်းထားသည်။
- [ ] Remote Admin access သည် SSH Tunnel/VPN သုံးသည်။
- [ ] External Database ဆိုပါက App Server source IP ကိုသာ Allow လုပ်ထားသည်။

[Database Client Access လမ်းညွှန်](../database/database-client-access.md) ကိုကြည့်ပါ။

## 9. Users နှင့် Roles

- [ ] Administrator နှင့် Emergency Admin account အလုပ်လုပ်သည်။
- [ ] Application Admin, Normal User, Restricted User accounts ကို သီးခြားစမ်းသည်။
- [ ] Disabled User Login မဝင်နိုင်ပါ။
- [ ] Normal User သည် Admin-only Modules/Desk areas မမြင်နိုင်ပါ။
- [ ] User တစ်မျိုးချင်း Intended pages ကိုသာ Access ရသည်။

လိုအပ်ချက်မရှိဘဲ `Administrator`, `System Manager`, `Website Manager`,
`Developer` Roles မပေးပါနှင့်။

## 10. Login နှင့် Authentication

- [ ] Password Login/Reset နှင့် Email Link policy ကို စမ်း/ဆုံးဖြတ်ထားသည်။
- [ ] Two Factor Authentication နှင့် SSO policy မှတ်တမ်းတင်ထားသည်။
- [ ] SSO မရချိန် ဝင်နိုင်သော Emergency Admin account ရှိသည်။
- [ ] Disabled User Login မဝင်နိုင်ပါ။

SSO ကို User အနည်းငယ်ဖြင့် Pilot လုပ်ပြီးမှ Production အပြည့်ဖွင့်ပါ။

## 11. Email နှင့် Notifications

- [ ] Outgoing Email account ပြင်ထားပြီး Test Email အောင်မြင်သည်။
- [ ] Password Reset နှင့် Important Workflow notifications ရသည်။
- [ ] Sender name မှန်ပြီး SPF/DKIM/DMARC ပြင်ဆင်ထားသည်။

## 12. Branding နှင့် Localization

- [ ] Application name, Logo, Primary color, Public URL နှင့် Login text မှန်သည်။
- [ ] Required Languages နှင့် Unicode text မှန်ကန်စွာပြသည်။
- [ ] Branding ပြောင်းပြီး Browser Hard Refresh စမ်းထားသည်။
- [ ] Translation/Branding ကို Permanent Custom App ထဲတွင် ထိန်းထားသည်။

## 13. Application Data

- [ ] Production Master Data/Required Records/Workflows ပြည့်စုံသည်။
- [ ] Demo/Test Records ကို ဖယ်ရှား သို့မဟုတ် ဖုံးထားသည်။
- [ ] Attachments, Public/Private Files, Print Formats/Exports စမ်းထားသည်။
- [ ] User access rules မှန်သည်။

## 14. Access Control

- [ ] Public/Internal/Private pages များကို ရည်ရွယ်ချက်အတိုင်းခွဲထားသည်။
- [ ] Restricted Records ကို Server-side Permission ဖြင့် ကာကွယ်ထားသည်။
- [ ] Managers/Admins တွင် လိုအပ်သော Permission သာရှိသည်။
- [ ] Admin-only Menu ကို Normal User မမြင်နိုင်ပါ။
- [ ] Permission ကို User accounts အမှန်ဖြင့် စမ်းထားသည်။

## 15. File Uploads နှင့် Storage

- [ ] Upload size limit နှင့် File storage strategy ကို ဆုံးဖြတ်ထားသည်။
- [ ] Large File, Private File, Public File Upload/Open/Download စမ်းထားသည်။
- [ ] Disk/Object Storage capacity လုံလောက်ပြီး Backup တွင် Files ပါသည်။

```yaml
CLIENT_MAX_BODY_SIZE: 50m
```

လိုအပ်မှသာ Limit တိုးပါ။

## 16. Performance

- [ ] Login/Main pages/List/Report pages များ လက်ခံနိုင်သောအမြန်နှုန်းရှိသည်။
- [ ] File Upload/Download, Workers နှင့် Scheduler အလုပ်လုပ်သည်။
- [ ] Normal/Expected Load အောက်တွင် CPU, Memory, Disk, Queue ကိုစစ်ထားသည်။

```bash
docker stats
```

## 17. Security

- [ ] Firewall ဖွင့်ထားပြီး Required ports သာ Allow လုပ်ထားသည်။
- [ ] Database/Redis/Internal Services Public မဖွင့်ထားပါ။
- [ ] Default Accounts/Passwords ကိုဖယ်ရှား သို့မဟုတ် Secure လုပ်ထားသည်။
- [ ] Backups/Secrets ကာကွယ်ထားပြီး HTTPS အလုပ်လုပ်သည်။
- [ ] Reverse Proxy Security Headers နှင့် Restricted SSH စစ်ထားသည်။

```text
Public: 80 (HTTPS redirect), 443 (HTTPS)
Restricted: 22 (SSH)
Private: 3306/3307, 8080, 8787, Redis and MinIO admin ports
```

## 18. Monitoring နှင့် Logs

- [ ] Docker Log rotation, Error Logs, Backup Logs နှင့် Disk usage စောင့်ကြည့်သည်။
- [ ] Operator က Logs ကြည့်နည်းသိပြီး Service-down/Disk-full Alerts ရှိသည်။

```bash
./ops.sh status
./ops.sh logs
./ops.sh logs backend --follow
```

## 19. Upgrade နှင့် Rollback

- [ ] Current Git Commit, Docker image Tag နှင့် App versions မှတ်တမ်းရှိသည်။
- [ ] Update မတိုင်မီ Backup ယူထားသည်။
- [ ] Rollback steps ရေးထားပြီး Update/Migration ကို Non-production တွင် စမ်းထားသည်။

```text
backup -> build/deploy -> migrate -> smoke test -> verify
```

Data deletion ကို ရည်ရွယ်ပြီး အတည်ပြုခြင်းမရှိဘဲ Production တွင်
`cleanup.sh` မသုံးပါနှင့်။

## 20. Go-Live Smoke Test

- [ ] Production URL ဖွင့်၍ Administrator/Application Admin/Normal User ဖြင့် Login ဝင်သည်။
- [ ] Main pages နှင့် Existing Record များဖွင့်သည်။
- [ ] ခွင့်ပြုထားလျှင် Test Record Create/Update လုပ်သည်။
- [ ] File Upload/Open, Workflow/Background job, Logout/Password Reset စမ်းသည်။
- [ ] လိုအပ်ပါက Mobile Browser စမ်းသည်။

## 21. Launch Day

- [ ] Backup, Reverse Proxy, HTTPS နှင့် Container Health အောင်မြင်သည်။
- [ ] Email Test အောင်မြင်သည်။
- [ ] Support contact, User Guide, Known Issues နှင့် Rollback Plan အဆင်သင့်ဖြစ်သည်။

```bash
docker compose ps
```

## 22. Go-Live ပြီးနောက်

- [ ] ပထမ 24 နာရီ Logs, Failed Logins, Email delivery နှင့် User access စောင့်ကြည့်သည်။
- [ ] User Feedback, Memory/Disk usage နှင့် Daily Backup အောင်မြင်မှု စစ်သည်။
- [ ] ပထမ Production Maintenance window သတ်မှတ်သည်။

## Final Approval

- [ ] HTTPS အလုပ်လုပ်သည်။
- [ ] Backup နှင့် Restore အတည်ပြုပြီးဖြစ်သည်။
- [ ] Admin/Normal User Login နှင့် Permissions မှန်သည်။
- [ ] Default Password နှင့် Git ထဲဝင်နေသော Secret မရှိပါ။
- [ ] Rollback Plan အဆင်သင့်ဖြစ်သည်။

```text
Name:
Role:
Date:
Notes:
```
