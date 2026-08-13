# Cleanup Script (`cleanup.sh`)

`cleanup.sh` သည် Project environment ကို data မရှိသော အစအခြေအနေသို့
အပြည့်အဝ reset လုပ်ရန် သုံးသည့် utility ဖြစ်သည်။

## ⚠️ အန္တရာယ်ရှိသော Operation

ဒီ Script ကို run ပြီးလျှင် ပြန်ပြင်၍မရပါ။ အောက်ပါတို့ကို လုပ်မည်။

- Project containers အားလုံးကို ရပ်ပြီး ဖျက်မည်။
- MariaDB (Frappe)၊ PostgreSQL (Keycloak) Database နှင့် uploaded files
  ပါဝင်သော Data volumes အားလုံးကို အမြဲတမ်းဖျက်မည်။
- `setup.sh` ဖန်တီးထားသော local Custom image ကို ဖျက်မည်။
- Orphaned Docker build layers များကိုရှင်း၍ Disk space လွတ်စေမည်။

အရေးကြီး Data များကို စစ်ဆေးပြီး Backup အောင်မြင်ကြောင်း အတည်ပြုထားခြင်း
မရှိပါက မလုပ်ပါနှင့်။

## Script လုပ်ဆောင်ပုံ

1. `docker compose down -v` ဖြင့် Services နှင့် volumes ကိုဖယ်ရှားသည်။
2. တူညီသော host ပေါ်ရှိ တခြား Docker project များ မထိခိုက်စေရန် သတ်မှတ်ထားသော
   `STACK_ID` ပါသည့် resource များကိုသာ target လုပ်သည်။
3. Local `CUSTOM_IMAGE` ကို ရှာပြီးဖျက်သည်။
4. Stack သုံးထားသော virtual networks ကို ဖယ်ရှားသည်။

## အသုံးပြုပုံ

```bash
chmod +x cleanup.sh
./cleanup.sh
```

## ဘယ်အချိန်သုံးရမလဲ

- System တစ်ခုလုံးကို Data မပါဘဲ အစမှပြန်တင်ရန် အတည်ပြုပြီးသောအခါ။
- Database schema အသစ်ဖြင့် Stack ကို လုံးဝပြန်ဆောက်ရန်လိုသောအခါ။
- Server ကို decommission လုပ်သောအခါ။

Configuration error ရှိရုံဖြင့် ပထမဆုံးဖြေရှင်းနည်းအဖြစ် မသုံးပါနှင့်။ Logs၊
configuration နှင့် service health ကိုအရင်စစ်ပါ။
