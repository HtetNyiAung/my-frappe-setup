# Documentation အညွှန်း

ဒီ folder က `my-frappe-setup` အတွက် documentation အားလုံးရဲ့ အဓိက index
ဖြစ်ပါတယ်။ ဘယ်အချိန်မှာ ဘယ် script ကို run ရမလဲ အရင်ကြည့်လိုပါက
[Script အသုံးပြုမှုလမ်းညွှန်](guide/script-usage-guide-my.md) ကို စတင်ဖတ်ပါ။

## အဓိက Guide

- [Script အသုံးပြုမှုလမ်းညွှန်](guide/script-usage-guide-my.md) — First Setup,
  Deployment နဲ့ day-to-day Operations အတွက် command ရွေးချယ်နည်း

## ပထမဆုံး Setup

- [Frappe Docker ပထမဆုံး Setup](setup/setup.md) — Site အသစ်အတွက် First Setup
- [Hosting Checklists](setup/checklists.md) — Hosting မလုပ်မီနှင့် Go-Live
  မတိုင်မီ checklist

## Deployment

- [Application Deployment လမ်းညွှန်](deployment/deploy.md) — Existing Site ကို Code
  update လုပ်သည့် workflow
- [Production Mode Operations](deployment/production-mode.md) — Production Settings
- [Production Launch Checklist](deployment/production-launch-checklist.md)
- [Deployment Architecture](deployment/deployment-architecture.md) — App Server,
  Database Server နှင့် Storage Server Architecture
- [Reverse Proxy လမ်းညွှန်](deployment/reverse-proxy-guide.md)
- [Legacy Update Command](deployment/update.md) — `update.sh` compatibility
  information

## နေ့စဉ် Operations

- [Runtime Operations လမ်းညွှန်](operations/operations.md) — Status, Restart, Cache,
  Migration, Logs နဲ့ Maintenance Mode
- [Logs](operations/logs.md)
- [Cleanup](operations/cleanup.md)
- [Backup Script](operations/backup.md)
- [Restore Script](operations/restore.md)
- [Backup Automation လမ်းညွှန်](operations/backup-automation-guide.md)

## Database

- [External MariaDB First Setup](database/external-database-ubuntu.md)
- [Existing Site External Database Migration](database/external-database.md)
- [Database Client Access](database/database-client-access.md)

## Storage

- [MinIO S3 Integration လမ်းညွှန်](storage/minio-s3-integration-guide.md)

## Integrations

- [Keycloak နှင့် Frappe SSO](integrations/keycloak-frappe-setup-guide.md)
- [Authentik နှင့် Frappe](integrations/authentik-frappe-setup-guide.md)
- [Gmail နှင့် Outlook Email](integrations/email-outlook-setup-guide.md)
- [changAI Setup](integrations/changai-setup-guide.md)

## Development

- [Custom App Development လမ်းညွှန်](development/custom-app-setup-guide.md)

## User Guides

- [Digital Learning Administrator နှင့် Learner Guide](user-guides/lms-user-admin-guide.md)

## Documentation ရေးသားမှုစည်းမျဉ်း

- Command အားလုံးကို သက်ဆိုင်ရာ Guide က တခြားနေရာမသတ်မှတ်ထားလျှင်
  `docker-setup/` folder မှ run ပါ။
- Password, GitHub Token, real IP address နဲ့ customer data ကို documentation
  ထဲ မထည့်ပါနှင့်။
- File တစ်ခုရွှေ့ပါက Root `README.md`, `docker-setup/README.md` နှင့် Relative
  Markdown links အားလုံးကို တစ်ပြိုင်နက် update လုပ်ပါ။
- ရှင်းလင်းချက်ကို Myanmar-first ရေးပြီး Command, Environment Variable, Path,
  Exact UI Label နှင့် Technical Term များကို English အတိုင်းထားပါ။
