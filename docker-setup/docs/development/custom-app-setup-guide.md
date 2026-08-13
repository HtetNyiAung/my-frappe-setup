# Custom App Development လမ်းညွှန် (Frappe Docker)

ဒီလမ်းညွှန်သည် Docker-based Development environment ထဲတွင် Custom Frappe
App တစ်ခုကို ဖန်တီးခြင်း၊ Version Control သတ်မှတ်ခြင်း၊ Setup နှင့်ချိတ်ဆက်ခြင်း၊
Development လုပ်ခြင်းတို့ကို ရှင်းပြထားသည်။

## 1. Custom App အသစ်ဖန်တီးခြင်း

Containers များ run နေချိန်တွင် Backend container ထဲဝင်ပါ။

```bash
cd docker-setup
docker compose exec backend bash
```

App boilerplate ဖန်တီးပါ။

```bash
bench new-app <app_name>
```

Prompt တွင် Title, Description, Publisher စသည့် အချက်အလက်များကို ဖြည့်ပါ။
App သည် Container ထဲတွင်သာရှိပါက Host သို့ တစ်ကြိမ်ကူးပါ။ အောက်ပါ
`<app_name>` နှင့် Container အမည်ကို မိမိ environment နှင့်ကိုက်ညီအောင်
ပြောင်းရမည်။

```bash
# Host တွင် folder ကိုအရင်ဖန်တီးပါ
mkdir -p ../apps/<app_name>

# Container မှ Host သို့ code ကူးပါ
docker cp docker-setup-backend-1:/home/frappe/frappe-bench/apps/<app_name>/. ../apps/<app_name>/
```

## 2. Git ဖြင့် Version Control လုပ်ခြင်း

Custom App တစ်ခုချင်းကို သီးခြား Git repository ထားရန် အကြံပြုသည်။

```bash
cd ../apps/<app_name>
git init
git remote add origin https://github.com/<owner>/<repository>.git
git add .
git commit -m "chore: initialize custom app structure"
git branch -M main
git push -u origin main
```

`git push -f` သည် Remote history ကို overwrite လုပ်နိုင်သောကြောင့် ပုံမှန်
initial push တွင် မသုံးပါနှင့်။ Private repository အတွက် credential ကို URL
ထဲတွင် မထည့်ဘဲ Git credential manager, SSH key သို့မဟုတ် approved secret
mechanism ကို သုံးပါ။

## 3. Setup ထဲသို့ App ထည့်ခြင်း

### Step 1 — `apps.json` ပြင်ခြင်း

Docker build က repository ကို clone နိုင်ရန် `docker-setup/apps.json` ထဲသို့
App ကို ထည့်ပါ။

```json
{
  "name": "<app_name>",
  "url": "https://github.com/<owner>/<repository>.git",
  "branch": "main"
}
```

### Step 2 — Development Volume Mount

Host code ပြောင်းလဲမှုကို Container ထဲတွင် ချက်ချင်းမြင်လိုပါက
`docker-setup/pwd-with-apps.yml` ရှိ လိုအပ်သော Services များတွင် Volume mount
ထည့်ပါ။ Production image အတွက် bind mount မသုံးဘဲ Deployment workflow အတိုင်း
image ထဲသို့ build လုပ်ပါ။

```yaml
services:
  backend:
    volumes:
      - ../apps/<app_name>:/home/frappe/frappe-bench/apps/<app_name>
```

## 4. Development Workflow

Volume mount သုံးထားပါက Host ရှိ Python/JS file ပြောင်းလဲမှုများကို Container
တွင် ချက်ချင်းတွေ့နိုင်ပြီး Development တိုင်း image ပြန်ဆောက်ရန် မလိုပါ။

DocType အသစ်ဖန်တီးခြင်း သို့မဟုတ် field ပြင်ခြင်းကဲ့သို့ Database schema
ပြောင်းလဲမှုရှိပါက—

```bash
./ops.sh migrate
```

## 5. Setup နှင့် Deployment

- ပထမဆုံး Site installation အတွက် `./setup.sh` ကို သုံးပါ။
- Site ရှိပြီးနောက် Code/App update အတွက် `./deploy.sh check`,
  `./deploy.sh plan`, `./deploy.sh apply` ကို အစဉ်လိုက်သုံးပါ။
- Deployment workflow သည် image build၊ verified Backup၊ App sync/install၊
  Migration၊ Cache clear နှင့် Verification ကို ထိန်းချုပ်လုပ်ဆောင်ပေးသည်။

အသေးစိတ်ကို [Script အသုံးပြုမှုလမ်းညွှန်](../guide/script-usage-guide-my.md)
တွင် ဖတ်ပါ။

## 6. ပြဿနာဖြေရှင်းခြင်း

- **`403 Not Permitted` after OAuth login** — OAuth login flow တွင် Server
  Script ကိုမမှီခိုဘဲ Custom App ၏ `hooks.py` နှင့် server-side permission
  logic ကို သုံးပါ။
- **File permission error** — Ownership ကို မပြောင်းမီ affected path နှင့်
  လက်ရှိ owner ကို `ls -la` ဖြင့်စစ်ပါ။ လိုအပ်မှသာ မိမိ App folder အတိအကျကို
  target လုပ်ပါ။

```bash
sudo chown -R "$USER":"$USER" ../apps/<app_name>
```

Broad path သို့မဟုတ် unresolved variable ကို `chown -R` နှင့် မသုံးပါနှင့်။
