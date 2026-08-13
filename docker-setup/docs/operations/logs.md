# Logs Script (`logs.sh`)

`logs.sh` သည် Application stack တစ်ခုလုံး၏ Logs ကို အချိန်နှင့်တပြေးညီ
စောင့်ကြည့်ရန် သုံးသော utility ဖြစ်သည်။

## ဘာတွေလုပ်ပေးသလဲ

အောက်ပါ Stack နှစ်ခုရှိ Container အားလုံး၏ Logs ကို တစ်နေရာတည်းတွင် ပြသည်။

1. **Frappe Stack** — `pwd-with-apps.yml` ထဲရှိ backend, frontend, workers,
   Redis စသည့် Containers။
2. **Keycloak Stack** — `docker-compose.keycloak.yml` ထဲရှိ Keycloak နှင့်
   PostgreSQL Containers။

## အသုံးပြုပုံ

```bash
chmod +x logs.sh
./logs.sh
```

- Log streaming ရပ်ရန် `Ctrl+C` နှိပ်ပါ။
- Terminal output များလွန်းခြင်းမရှိစေရန် default အနေဖြင့် နောက်ဆုံး 100 lines
  ကိုသာ စပြသည်။

## ဘယ်အချိန်အသုံးဝင်သလဲ

- Keycloak နှင့် Frappe Logs နှစ်ခုလုံးကို တွဲကြည့်ရသော SSO Redirect error။
- Background task failure။
- Startup error သို့မဟုတ် connectivity timeout။

Service တစ်ခုချင်းအလိုက်စစ်ရန် `./ops.sh logs <service>` ကို အသုံးပြုနိုင်သည်။
