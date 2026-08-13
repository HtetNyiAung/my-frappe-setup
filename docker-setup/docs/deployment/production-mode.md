# Production Mode Operations

Frappe တွင် Laravel ပုံစံ `APP_ENV=production` Switch တစ်ခုတည်းမရှိပါ။ ဒီ Setup
သည် `DEPLOYMENT_MODE=production` ကို Operational safety guard အဖြစ်သုံးပြီး
Production အတွက်လိုသော Frappe settings များကို သီးခြား Apply လုပ်သည်။
`frappe_docker/` အောက်ရှိ File များကို မပြင်ပါ။

## ဘာကိုပြင်ပေးသလဲ

`developer_mode=0` တစ်ခုတည်းဖြင့် Browser User များ Traceback မမြင်ကြောင်း
အာမမခံနိုင်ပါ။ **System Settings** ရှိ `allow_error_traceback` ကိုလည်း Disable
လုပ်ရသည်။ Script က နှစ်ခုစလုံးကို Apply/Verify လုပ်သည်။

ဒါက Stack Trace, Internal path နှင့် SDK details ကို Browser error page မှ
ဖုံးကွယ်ပေးခြင်းသာဖြစ်ပြီး မူရင်း Application error ကို မပြင်ပါ။ ဥပမာ S3
`NoSuchKey` ဆိုပါက Object မရှိခြင်းကို Restore လုပ်ခြင်း သို့မဟုတ် Stale `File`
record ကို သီးခြားဖြေရှင်းရမည်။

## မလုပ်မီပြင်ဆင်ရန်

```env
DEPLOYMENT_MODE=production
REQUIRE_PRODUCTION_READY=1
PUBLIC_URL=https://app.example.com
BIND_ADDRESS=127.0.0.1
```

Default passwords အားလုံးပြောင်းပြီး `apps.json` Repository URL များထဲမှ
Credentials ကိုဖယ်ပါ။ HTTPS နှင့် Reverse Proxy အလုပ်လုပ်ကြောင်းစစ်ပါ။ Optional
Frappe Rate Limit ကို Value နှစ်ခုလုံးဖြင့် သတ်မှတ်နိုင်သည်။ Blank ထားလျှင်
Frappe Default ကို သုံးမည်။

```env
FRAPPE_RATE_LIMIT=1000
FRAPPE_RATE_LIMIT_WINDOW=3600
```

## Commands

Read-only readiness check—

```bash
./production.sh check
```

Check သည် Production guards, Default passwords, Git URL credentials, Backup
configuration, Containers, Site/Database access, Enable ဖြစ်ပါက S3 access နှင့်
လက်ရှိ Frappe Production settings ကို စစ်သည်။

Approved Maintenance window တွင် Apply လုပ်ရန်—

```bash
./production.sh apply
```

`PRODUCTION` ဟု အတည်ပြုပြီးနောက်—

1. Production preflight စစ်သည်။
2. Maintenance Mode ဖွင့်သည်။
3. `backup.sh --yes` run ပြီး မအောင်မြင်လျှင်ရပ်သည်။
4. Developer Mode, Tests နှင့် Browser Error Tracebacks ပိတ်သည်။
5. `PUBLIC_URL` မှ Frappe `host_name` သတ်မှတ်သည်။
6. Scheduler ဖွင့်ပြီး Optional Rate Limits Apply လုပ်သည်။
7. Migration နှင့် Cache clear လုပ်သည်။
8. Frappe Services Restart ပြီး Settings စစ်သည်။
9. Verification အောင်မြင်မှ Maintenance Mode ပိတ်သည်။

Trusted Automation တွင် `--yes` သုံးနိုင်သော်လည်း Preflight/Backup ကို
ကျော်မသွားပါ။ Post-deployment Read-only Verification—

```bash
./production.sh verify
```

## မအောင်မြင်သည့်အခါ

Maintenance Mode ဖွင့်ပြီးနောက် Apply မအောင်မြင်ပါက Site ကို Maintenance Mode
ဖြင့်ထားမည်။ `logs/scripts/production/` ရှိ Timestamped Log နှင့် Container
Logs ကိုစစ်ပါ။ ပြင်ပြီး Verify အောင်မြင်မှ `.env` ရှိ Container/Site အမည်အမှန်
သုံး၍ Maintenance Mode ပိတ်ပါ။

```bash
docker exec <backend-container> \
  bench --site <site-domain> set-maintenance-mode off
```

## Go-Live Review

Script သည် DNS, TLS, User Permissions, Restore Test သို့မဟုတ် Rollback
Decision ကို အတည်မပြုနိုင်ပါ။ Public launch မတိုင်မီ
[Production Launch Checklist](production-launch-checklist.md) ကို ပြီးအောင်လုပ်ပါ။
