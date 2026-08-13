# Documentation Index

ဒီ folder က `my-frappe-setup` အတွက် documentation အားလုံးရဲ့ အဓိက index
ဖြစ်ပါတယ်။ ဘယ်အချိန်မှာ ဘယ် script ကို run ရမလဲ အရင်ကြည့်လိုပါက
[Myanmar Script Usage Guide](guide/script-usage-guide-my.md) ကို စတင်ဖတ်ပါ။

## Guide

- [Myanmar Script Usage Guide](guide/script-usage-guide-my.md) — First Setup,
  Deployment နဲ့ day-to-day Operations အတွက် command ရွေးချယ်နည်း

## Setup

- [Frappe Docker Setup](setup/setup.md) — Site အသစ်အတွက် First Setup
- [Hosting Checklists](setup/checklists.md) — Hosting မလုပ်မီနှင့် Go-Live
  မတိုင်မီ checklist

## Deployment

- [Application Deployment](deployment/deploy.md) — Existing site ကို code
  update လုပ်သည့် workflow
- [Production Mode](deployment/production-mode.md) — Production settings
- [Production Launch Checklist](deployment/production-launch-checklist.md)
- [Deployment Architecture](deployment/deployment-architecture.md) — App,
  Database နဲ့ Storage servers architecture
- [Reverse Proxy](deployment/reverse-proxy-guide.md)
- [Legacy Update Command](deployment/update.md) — `update.sh` compatibility
  information

## Operations

- [Runtime Operations](operations/operations.md) — Status, restart, Cache,
  Migration, Logs နဲ့ Maintenance Mode
- [Logs](operations/logs.md)
- [Cleanup](operations/cleanup.md)
- [Backup](operations/backup.md)
- [Restore](operations/restore.md)
- [Backup Automation](operations/backup-automation-guide.md)

## Database

- [External MariaDB First Setup](database/external-database-ubuntu.md)
- [Existing Site External Database Migration](database/external-database.md)
- [Database Client Access](database/database-client-access.md)

## Storage

- [MinIO S3 Integration](storage/minio-s3-integration-guide.md)

## Integrations

- [Keycloak and Frappe](integrations/keycloak-frappe-setup-guide.md)
- [Authentik and Frappe](integrations/authentik-frappe-setup-guide.md)
- [Outlook Email](integrations/email-outlook-setup-guide.md)
- [changAI](integrations/changai-setup-guide.md)

## Development

- [Custom App Setup](development/custom-app-setup-guide.md)

## User Guides

- [LMS User and Administrator Guide](user-guides/lms-user-admin-guide.md)

## Documentation Rules

- Command အားလုံးကို အများအားဖြင့် `docker-setup/` folder မှ run ပါ။
- Password, GitHub Token, real IP address နဲ့ customer data ကို documentation
  ထဲ မထည့်ပါနှင့်။
- File တစ်ခုရွှေ့ပါက root `README.md`, `docker-setup/README.md` နှင့် relative
  Markdown links အားလုံးကို တစ်ပြိုင်နက် update လုပ်ပါ။
