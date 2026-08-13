# External MariaDB အသုံးပြုခြင်း

ဒီ project က Docker Compose ထဲက bundled Local MariaDB သို့မဟုတ် သီးခြား
Database Server ပေါ်က External MariaDB နှစ်မျိုးလုံးကို support လုပ်ပါတယ်။
Existing installation တွေမပျက်စေရန် Default က Local Database ဖြစ်ပါတယ်။

အသစ်စတင်သည့် Fresh First Setup အတွက် MariaDB install, security, Firewall နဲ့
`.env` configuration ကို
[External MariaDB on Ubuntu](external-database-ubuntu.md) မှာ တစ်ဆင့်ချင်း
ဖတ်နိုင်ပါတယ်။ ဒီ document က Database Mode ရွေးချယ်ခြင်း၊ Existing Site
Migration၊ Rollback နဲ့ Credential Repair အတွက် အဓိက reference ဖြစ်ပါတယ်။

## ဘယ် Guide ကိုသုံးရမလဲ

| လက်ရှိအခြေအနေ | သုံးရမည့်နည်း |
|---|---|
| Site နဲ့ Site Database လုံးဝမရှိသေး | Fresh First Setup guide |
| Local MariaDB ထဲမှာ လက်ရှိ Site Data ရှိပြီးသား | ဒီ document ရဲ့ Existing Site Migration |
| Database export/import လုပ်ပြီးသား | Existing Site Migration နဲ့ Verification |
| Database Client ကနေဝင်လို | [Database Client Access](database-client-access.md) |

> `DB_HOST` ပြောင်းရုံနဲ့ Database Data ကို copy သို့မဟုတ် migrate မလုပ်ပါ။

## Database Modes

### Bundled Local MariaDB

```env
DATABASE_MODE=local
DB_HOST=db
DB_PORT=3306
```

ဒီ mode မှာ App Services နဲ့ MariaDB က Docker Compose Network တစ်ခုတည်းထဲမှာ
ရှိပြီး `db` Service Name ကို Host အဖြစ်သုံးပါတယ်။

### External MariaDB

```env
DATABASE_MODE=external
DB_HOST=<DB_PRIVATE_IP_OR_INTERNAL_DNS>
DB_PORT=3306
DB_ROOT_USERNAME=frappe_provisioner
DB_ROOT_PASSWORD=<STRONG_PROVISIONER_PASSWORD>
DB_NAME=
DB_PASSWORD=<STRONG_SITE_DATABASE_PASSWORD>
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false
```

`DB_HOST` ကို App Server နဲ့ Frappe Containers နှစ်ခုလုံးက resolve/connect
လုပ်နိုင်ရပါမယ်။ `localhost` သို့မဟုတ် `127.0.0.1` မသုံးပါနှင့်။ Container
အတွင်းက အဲဒီ address တွေဟာ Container ကိုယ်တိုင်ကို ရည်ညွှန်းပါတယ်။

### `.env` variables ရဲ့တာဝန်

| Variable | အသုံးပြုပုံ |
|---|---|
| `DATABASE_MODE` | `local` သို့မဟုတ် `external` ရွေးပေးတယ် |
| `DB_HOST` | Frappe ကချိတ်မည့် Database Server address |
| `DB_PORT` | MariaDB TCP Port |
| `DB_ROOT_USERNAME` | Fresh Site provisioning သို့မဟုတ် controlled repair အတွက် privileged User |
| `DB_ROOT_PASSWORD` | Provisioning User Password |
| `DB_NAME` | Fresh Site ဖန်တီးချိန် သုံးမည့် Database Name; အလွတ်ထားလျှင် Frappe က generate လုပ်တယ် |
| `DB_PASSWORD` | Fresh Site Runtime Database User Password |
| `ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR` | External credential automatic repair ကို explicit ခွင့်ပြုမပြု |

Existing Site အတွက် Runtime Database Name, User နဲ့ Password ကို
`sites/<SITE_NAME>/site_config.json` ကဆုံးဖြတ်ပါတယ်။ `.env` ထဲက `DB_NAME` နဲ့
`DB_PASSWORD` ပြောင်းခြင်းက Existing Site ရဲ့ credentials ကို အလိုအလျောက်
မပြောင်းပါ။

## Database Server Requirements

- Deploy ထားသည့် Frappe version နဲ့ compatible ဖြစ်သော MariaDB release သုံးပါ။
  ဒီ project ရဲ့ Frappe `version-16` setup က MariaDB `11.8` ကိုရည်ရွယ်ထားပါတယ်။
  Provisioning သို့မဟုတ် Upgrade မလုပ်မီ official requirements ကိုပြန်စစ်ပါ။
- Character Set ကို `utf8mb4` နဲ့ Collation ကို `utf8mb4_unicode_ci` သုံးပါ။
- MariaDB TCP Connection ကို App Server Private IP သို့မဟုတ် approved Private
  Network ကနေပဲ Allow လုပ်ပါ။
- Port `3306` ကို Public Internet သို့မဖွင့်ပါနှင့်။
- Remote `root` အစား Temporary Provisioning User သုံးပါ။
- Frappe Runtime User ကို သူ့ Site Database တစ်ခုတည်းအတွက် Permission ပေးပါ။
- Untrusted Network ကိုဖြတ်ရပါက Transport Encryption သုံးပါ။
- Database Server အတွက် independent Backup နဲ့ Restore Test ထားပါ။

Temporary Provisioning User က `bench new-site` အချိန်မှာ Site Database နဲ့
Runtime User ဆောက်ရန်လိုအပ်ပါတယ်။ Fresh Setup နဲ့ Verification အောင်မြင်ပြီး
Automated Credential Repair မလိုတော့ပါက ဒီ User ကိုဖျက်နိုင်ပါတယ်။

## Fresh Site

Fresh Site ဆိုတာ App Server မှာ Site Directory မရှိသေးသလို External MariaDB
မှာလည်း Target Site Database သို့မဟုတ် Imported Data မရှိသေးတာကိုဆိုလိုပါတယ်။

1. External MariaDB Server နဲ့ Private Firewall Rule ကိုပြင်ဆင်ပါ။ Ubuntu
   အတွက် [First Setup Guide](external-database-ubuntu.md) ကိုလိုက်နာပါ။
2. `.env` မှာ `DATABASE_MODE=external` နဲ့ External Database variables ထည့်ပါ။
3. `./setup.sh` run ပြီး Summary ထဲက Database Target ကိုစစ်ပါ။
4. မှန်မှ `SETUP` လို့ Confirm လုပ်ပါ။
5. Login, Record Create/Read, Background Jobs, Backup နဲ့ Restore Test စစ်ပါ။

External Mode မှာ `setup.sh` က Local `db` Service ကို မစတင်ဘဲ Frappe, Redis
နဲ့ Workers ကိုစတင်ပါတယ်။ Site မဆောက်မီ Network Reachability နဲ့ Provisioning
Credentials ကို Preflight စစ်ပါတယ်။

Local `db` Container ရှိပြီးသားကနေ External Mode ပြောင်းလျှင် Setup က Rollback
အတွက် Local Database Volume ကို အလိုအလျောက်မဖျက်ပါ။ External Database ကို
အပြည့်အဝ Verify လုပ်ပြီးမှ Local `db` Service ကို Data မဖျက်ဘဲ ရပ်နိုင်ပါတယ်။

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml stop db
```

<a id="existing-site-migration"></a>

## Existing Site Migration

Existing Site Migration ကို approved Maintenance Window အတွင်းလုပ်ပါ။ ဒီ
procedure ရဲ့ရည်ရွယ်ချက်က Final Backup ယူနေချိန်နဲ့ Database Import လုပ်နေချိန်
မှာ Application Write အသစ်မဝင်စေရန်ဖြစ်ပါတယ်။

### Migration မစခင် စုဆောင်းထားရမည့်အချက်များ

- `SITE_DOMAIN`
- လက်ရှိ `site_config.json` ထဲက `db_name` နဲ့ `db_user`
- Local Database Backup နဲ့ Files Backup
- External Database Server address နဲ့ approved Firewall Rule
- Rollback အတွက် လက်ရှိ Local Database Volume
- Maintenance Window နဲ့ responsible operator

Password ကို Terminal output, Documentation သို့မဟုတ် Screenshot ထဲ
မထုတ်ပါနှင့်။

### Migration Procedure

1. `.env` ကို `DATABASE_MODE=local` အတိုင်းထားပြီး `./backup.sh` run ပါ။
2. Backup ထဲမှာ non-empty Database dump, Public Files နဲ့ Private Files
   archives ပါကြောင်း Verify လုပ်ပါ။ Rollback အတွက် Local Database Volume ကို
   မပြောင်းဘဲထားပါ။
3. Maintenance Mode ဖွင့်ပြီး Scheduler နဲ့ Queue Workers ကိုရပ်ပါ။ ဒီလိုလုပ်တာက
   Final Dump ယူနေစဉ် Write အသစ်မဝင်စေရန်ဖြစ်ပါတယ်။
4. Final Backup ယူပြီး `*-database.sql.gz` ကို External Database ထဲ Import
   လုပ်ပါ။
5. External Database မှာ `site_config.json` ထဲက Database Name, Runtime User
   နဲ့ Password အတိုင်း Account ဆောက်ပါ။ Runtime User ကို အဲဒီ Database
   တစ်ခုတည်းအတွက် Permission ပေးပါ။
6. `.env` မှာ `DATABASE_MODE=external`, `DB_HOST`, `DB_PORT` နဲ့ controlled
   Reconfiguration အတွက်လိုအပ်သည့် admin credentials ကိုထည့်ပါ။
7. `./setup.sh --reconfigure` run ပါ။ ဒီ explicit flag က Existing Site အတွက်
   `common_site_config.json` ကို External Host သို့ပြောင်းခွင့်ပေးပါတယ်။ Site က
   Target Database ကို authenticate မလုပ်နိုင်ရင် Setup ရပ်သွားပါမယ်။
8. `./ops.sh status` run ပြီး Services, Site နဲ့ Database Connection အားလုံး
   `[PASS]` ဖြစ်ကြောင်းစစ်ပါ။
9. Login, Record Read/Write, Background Jobs, Scheduler, File Access, Backup
   နဲ့ Test Restore ကိုစစ်ပါ။
10. စစ်ဆေးချက်အားလုံးအောင်မှ Maintenance Mode ပိတ်ပါ။

Migration အတွင်း Rollback အတွက် Local Database Volume ကိုထားရှိနေသရွေ့
`cleanup.sh` မ run ပါနှင့်။ `cleanup.sh` က project Docker Volumes ကိုဖျက်နိုင်ပါတယ်။

## Verification Checklist

- [ ] App Server က `<DB_PRIVATE_IP>:3306` ကို `nc` Test အောင်ပါတယ်။
- [ ] `common_site_config.json` မှာ External `db_host` နဲ့ `db_port` မှန်ပါတယ်။
- [ ] `site_config.json` ထဲက `db_name` နဲ့ `db_user` က Imported Database နဲ့
      ကိုက်ညီပါတယ်။
- [ ] `bench --site <SITE_NAME> list-apps` အောင်ပါတယ်။
- [ ] Administrator Login အောင်ပါတယ်။
- [ ] Test Record Create, Read နဲ့ Update အောင်ပါတယ်။
- [ ] Scheduler နဲ့ Queue Workers running ဖြစ်ပါတယ်။
- [ ] Public/Private Files ဖွင့်နိုင်ပါတယ်။
- [ ] External Database ကိုအသုံးပြုပြီး Backup အသစ်ယူနိုင်ပါတယ်။
- [ ] Restore Procedure ကို Test Environment မှာစမ်းပြီးပါပြီ။

## Rollback

### External Database မှာ Production Write မစသေးခင်

1. `.env` မှာ `DATABASE_MODE=local`, `DB_HOST=db`, `DB_PORT=3306` ပြန်ထားပါ။
2. `./setup.sh --reconfigure` run ပြီး Application ကို မပြောင်းထားသည့် Local
   Database ပြန်ချိတ်ပါ။
3. `./ops.sh status` နဲ့ functional tests အောင်မှ Maintenance Mode ပိတ်ပါ။

### External Database မှာ Write အသစ်ဝင်ပြီးနောက်

Old Local Database ကို တန်းပြန်ချိတ်ပါက External Database ပေါ်ရောက်ပြီးသား
Record အသစ်တွေ ပျောက်သွားပါမယ်။ ဒီအခြေအနေမှာ Reverse Migration သို့မဟုတ်
Verified Backup Restore လိုအပ်ပါတယ်။ Database နဲ့ Code Version compatibility
ကိုစစ်ပြီး approved Recovery Plan နဲ့သာလုပ်ပါ။

## Credential Repair

External Database အတွက် Automatic Credential Repair ကို Default အနေနဲ့
ပိတ်ထားပါတယ်။

```env
ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false
```

အောက်ပါအချက်တွေကို အတည်ပြုပြီး controlled repair အတွင်းမှသာ ခဏဖွင့်ပါ:

- `DB_HOST` နဲ့ `DB_PORT` က Target Database Server အမှန်ဖြစ်ခြင်း
- `DB_ROOT_USERNAME` က approved Provisioning User ဖြစ်ခြင်း
- Runtime Database Name နဲ့ User ကို Backup/`site_config.json` ဖြင့်
  အတည်ပြုပြီးဖြစ်ခြင်း
- Maintenance Window နဲ့ verified Backup ရှိခြင်း

Repair helper က Password ကို print မလုပ်ဘဲ Site Runtime User ကို သူ့ Database
တစ်ခုတည်းအတွက် Permission ပေးပါတယ်။ Repair ပြီးလျှင်
`ALLOW_EXTERNAL_DB_CREDENTIAL_REPAIR=false` ပြန်ထားပြီး မလိုတော့သည့်
Provisioning Credentials ကို `.env` မှဖယ်ရှားပါ။

## လုံခြုံရေးသတိပေးချက်

- Database Port ကို `0.0.0.0/0` အတွက် မဖွင့်ပါနှင့်။
- Provisioning User ကို Daily Workbench Access အတွက် မသုံးပါနှင့်။
- Database Runtime User ကို Application အပြင်ဘက် မမျှဝေပါနှင့်။
- `.env`, `site_config.json`, Database Dump နဲ့ Private Files Backup ကို Secret
  Data အဖြစ်ထိန်းသိမ်းပါ။
- Database Record သို့မဟုတ် Docker Volume ကို Troubleshooting shortcut အဖြစ်
  မဖျက်ပါနှင့်။
