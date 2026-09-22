# Runtime Operations လမ်းညွှန်

ရှိပြီးသား stack ကို နေ့စဉ်စီမံရန် `ops.sh` ကို အသုံးပြုပါ။ Script သည်
`.env` ကိုဖတ်ပြီး `docker-compose.override.yml` ရှိလျှင် အလိုအလျောက်
ထည့်သွင်းအသုံးပြုသည်။

## Status နှင့် Logs စစ်ဆေးခြင်း

```bash
./ops.sh status
./ops.sh logs
./ops.sh logs backend
./ops.sh logs backend --tail 200
./ops.sh logs backend --follow
```

`status` သည် အမြဲ run နေရမည့် Frappe service ခြောက်ခု၊ site ရှိ/မရှိနှင့်
Database connection ကို စစ်ဆေးပေးသည်။ ပြဿနာရှာဖွေရာတွင် `logs` ဖြင့်
service အားလုံးကိုကြည့်နိုင်ပြီး service အမည်ထည့်၍ သီးခြားစစ်နိုင်သည်။

## Restart နှင့် Cache ရှင်းခြင်း

```bash
./ops.sh restart
./ops.sh clear-cache
```

`restart` မလုပ်မီ `RESTART` ဟု အတည်ပြုရမည်။ `clear-cache` သည် image
ပြန်မဆောက်ဘဲ၊ Database migration မလုပ်ဘဲ Frappe site cache နှင့် website
cache ကို ရှင်းပေးသည်။

## ထိန်းချုပ်ထားသော Migration

Code ကို deploy လုပ်ပြီးသော်လည်း Migration ကို သီးခြားလုပ်ရန်လိုသည့်အခါမှ
အောက်ပါ command ကို အသုံးပြုပါ။

```bash
./ops.sh migrate
```

Script သည် `deploy.sh` သုံးသော Deployment lock ကိုပင်ယူပြီး Maintenance
Mode ဖွင့်ခြင်း၊ scheduler/queue worker များရပ်ခြင်း၊ စစ်ဆေးပြီး Backup
ဖန်တီးခြင်း၊ Migration လုပ်ခြင်း၊ Cache ရှင်းခြင်း၊ Restart နှင့် Verification
လုပ်ခြင်းတို့ကို အစဉ်လိုက်ဆောင်ရွက်သည်။ အားလုံးအောင်မြင်မှ Maintenance Mode
ကို ပိတ်ပေးသည်။

Migration မအောင်မြင်ပါက Maintenance Mode ကိုဖွင့်ထားပြီး writer service များ
ရပ်ထားမည်။ Error ကိုစစ်ပြီး ပြင်ဆင်ပြီးမှ ဆက်လုပ်ပါ။ Rollback လုပ်မည့် Code
version နှင့် Backup ကို သေချာရွေးချယ်စစ်ဆေးခြင်းမရှိဘဲ Database ကို
အလိုအလျောက် Restore မလုပ်ပါနှင့်။

## Maintenance Mode ပြန်လည်ထိန်းချုပ်ခြင်း

```bash
./ops.sh maintenance-on
./ops.sh maintenance-off
```

ဖွင့်ရာတွင် `MAINTENANCE`၊ ပိတ်ရာတွင် `RECOVERED` ဟု အတည်ပြုရသည်။ ထိုသို့
အတည်ပြုခိုင်းခြင်းကြောင့် မအောင်မြင်သေးသော Deployment ကို User များထံ
မတော်တဆပြန်ဖွင့်မိခြင်းမှ ကာကွယ်ပေးသည်။ ယုံကြည်ရသော Automation အတွက်
ပြောင်းလဲမှုလုပ်သည့် command များတွင် `--yes` ထည့်နိုင်သည်။

### Branded Gateway, Maintenance, and Timeout Pages

Maintenance Mode ဖွင့်ထားစဉ် Frappe backend ကပြန်ပေးသော HTTP `503` response ကို
Frontend Nginx ကဖမ်းယူပြီး `nginx/maintenance.html` ကိုပြသသည်။ Page သည်
Digital Portal branding၊ Myanmar message၊ responsive layout နှင့်
`ပြန်လည်စမ်းသပ်မည်` button ပါဝင်ပြီး HTTP status ကို `503 Service Unavailable`
အတိုင်းထိန်းထားသည်။ Search Engine များက index မလုပ်ရန်လည်း သတ်မှတ်ထားသည်။

Logo နှင့် Myanmar font ကို Site ၏ first-party `/assets` မှ load လုပ်ပြီး၊ Assets
မရရှိချိန်တွင်လည်း inline icon နှင့် System font fallback ဖြင့် message ကိုဖတ်ရှုနိုင်သည်။
Design သို့မဟုတ် message ပြင်ရန် အောက်ပါ files ကို ပြင်ပါ။

```text
nginx/maintenance.html
nginx/timeout.html
nginx/bad-gateway.html
```

Frontend Nginx က Frappe backend နှင့် ဆက်သွယ်မရသောအခါ HTTP `502` အတွက်
`nginx/bad-gateway.html` ကိုပြသည်။ Page သည် ပြဿနာကို generic message ဖြင့်
ဖော်ပြပြီး ပြန်စမ်းရန် button ပါသည်။ HTTP status ကို `502 Bad Gateway`
အတိုင်းထိန်းထားပြီး cache မလုပ်စေရန် header ထည့်ထားသည်။

Frontend Nginx က backend response ကို အချိန်မီ မရသောအခါ HTTP `504` အတွက်
`nginx/timeout.html` ကိုပြသည်။ Page သည် maintenance ဟု မဖော်ပြဘဲ
ဆက်သွယ်မှု အချိန်ကျော်သွားကြောင်း ပြပြီး ပြန်စမ်းရန် button ပါသည်။
HTTP status ကို `504 Gateway Timeout` အတိုင်းထိန်းထားပြီး cache မလုပ်စေရန်
header ထည့်ထားသည်။
အပြင်ဘက် Reverse Proxy က `502` သို့မဟုတ် `504` ကို အရင်ထုတ်ပါက ထို Proxy ၏
error page ကိုသာမြင်ရမည်။ ဤ pages သည် Frappe Frontend Nginx က ထုတ်သော
error များအတွက်ဖြစ်သည်။ Compose mount အသစ်ဖြစ်သဖြင့် deploy လုပ်ရာတွင် Frontend
container ကို recreate လုပ်ရန်လိုသည်။

Maintenance page ကိုစစ်ရန်:

```bash
./ops.sh maintenance-on
curl -I http://127.0.0.1:YOUR_FRAPPE_PORT/
./ops.sh maintenance-off
```

`YOUR_FRAPPE_PORT` နေရာတွင် `.env` ထဲရှိ `FRAPPE_PORT` value ကိုထည့်ပါ။ `curl`
output တွင် `503 Service Unavailable`, `Retry-After: 60` နှင့်
`Cache-Control: no-store, no-cache, must-revalidate` ပါရှိရမည်။ Planned
Maintenance အတွက် `503`၊ backend connection failure အတွက် `502`၊ backend
timeout အတွက် `504` ကို သီးခြား page ဖြင့်ပြထားသည်။ `setup.sh` စတင်ချိန်
Frontend container မတက်သေးပါက Browser က `ERR_CONNECTION_REFUSED` ကိုသာ
ပြမည်။ ထိုအခြေအနေကို ဤ `502` page ဖြင့် မဖုံးနိုင်ပါ။

## ဘယ် Script ကို ဘယ်အချိန်သုံးရမလဲ

| လိုအပ်ချက် | Command |
|---|---|
| Site ကို ပထမဆုံး install လုပ်ခြင်း | `./setup.sh` |
| Infrastructure သို့မဟုတ် generated Compose configuration ပြန်ပြင်ခြင်း | `./setup.sh --reconfigure` |
| ပုံမှန် Code/App update | `./deploy.sh apply` |
| Code build မပါသော Database migration | `./ops.sh migrate` |
| Cache ရှင်းခြင်း | `./ops.sh clear-cache` |
| Service restart | `./ops.sh restart` |
| Runtime ပြဿနာစစ်ခြင်း | `./ops.sh status`, `./ops.sh logs` |
| Production hardening | `./production.sh check/apply/verify` |
| Backup သို့မဟုတ် Restore | `./backup.sh`, `./restore.sh` |
