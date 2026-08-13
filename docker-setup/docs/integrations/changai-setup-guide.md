# changAI Setup လမ်းညွှန်

Frappe/ERPNext တွင် changAI AI Chat integration ပြင်ဆင်ခြင်း၊ Training လုပ်ခြင်း၊
စမ်းသပ်ခြင်းနှင့် ထိန်းသိမ်းခြင်းတို့အတွက် လမ်းညွှန်ဖြစ်သည်။ Third-party App/API
၏ UI, Model availability, Pricing နှင့် Data processing terms များ ပြောင်းနိုင်သဖြင့်
Production မဖွင့်မီ သက်ဆိုင်ရာ Official Documentation ကို ပြန်စစ်ပါ။

## လိုအပ်ချက်များ

- Frappe v16 Environment အလုပ်လုပ်ပြီး changAI App Install လုပ်ထားသည်။
- Approved Google Cloud Project ရှိသည်။
- လိုအပ်သော Gemini/Vertex AI API ကို Enable လုပ်ထားသည်။
- Data Privacy, Cost limit နှင့် User Permission policy ကို အတည်ပြုထားသည်။

## 1. Google Cloud Credentials

1. [Google AI Studio](https://aistudio.google.com/app/apikey) တွင် **Create API
   Key** နှိပ်၍ Key ထုတ်ပါ။
2. Google Cloud Console မှ Project ID/Number ကို မှတ်ထားပါ။
3. သက်ဆိုင်ရာ Project အတွက် [Vertex AI API](https://console.cloud.google.com/apis/library/aiplatform.googleapis.com)
   ကိုလိုအပ်ပါက Enable လုပ်ပြီး Activation အချိန်ပေးပါ။

API Key/Service Account JSON ကို Git, Documentation, Screenshot သို့မဟုတ် Log
ထဲ မထည့်ပါနှင့်။ Key leakage ဖြစ်ပါက ချက်ချင်း Revoke/Rotate လုပ်ပါ။

## 2. changAI Settings

Frappe Desk တွင် **changAI Settings** ကိုရှာဖွင့်ပါ။ App Version က Support
လုပ်သော Authentication mode ကိုရွေးပါ။

### API Key Mode

```text
Gemini API Key: <secret-api-key>
Gemini Project ID: <project-id>
Gemini_location: us-central1
Service Account Credential: leave empty
```

### Service Account Mode

```text
Gemini API Key: <secret-api-key-if-required>
Gemini Project ID: <project-id>
Gemini_location: us-central1
Service Account Credential: <service-account-json>
```

Production Service Account ကို Least-privilege Role ပေးပြီး Key rotation policy
ထားပါ။ Region ကို Data residency/policy နှင့် Model availability အရရွေးပါ။

## 3. Model Setup

1. **Download Embedding Model** နှိပ်ပြီး Success message ရသည်အထိစောင့်ပါ။
2. **Training** Tab တွင် **Update Master Data** နှိပ်ပါ။
3. Logs တွင် Error မရှိကြောင်းစစ်ပါ။

Download/Training သည် Network နှင့် Data size အလိုက် မိနစ်အနည်းငယ်ကြာနိုင်သည်။

## 4. Training Workflow

1. **changAI Settings → Training** ကိုဖွင့်ပါ။
2. Initial Test အတွက် Record Size `1000` ကဲ့သို့ အနည်းငယ်မှစပါ။
3. **Create training data** နှိပ်ပြီး ပြီးဆုံးကြောင်းစစ်ပါ။
4. **Module and Description** Table တွင် လိုအပ်သော Modules ကိုသာ တစ်ဆင့်ချင်း
   ထည့်ပါ။
5. **Update MasterData file** နှိပ်၍ Approved Master Data ကို Index လုပ်ပါ။
6. Custom Fields/DocTypes ပြောင်းထားလျှင် **Update Schema file** နှိပ်ပါ။
7. **Save** လုပ်ပြီး Test Queries ဖြင့် Permission နှင့် Answer မှန်ကန်မှု စစ်ပါ။

```text
Set Record Size
  -> Create Training Data
  -> Add Approved Modules
  -> Update MasterData
  -> Update Schema
  -> Save
  -> Permission-aware Test
```

Master Data/Schema ကို AI Provider သို့ပို့ခြင်းရှိ/မရှိကို App Implementation
နှင့် Provider settings မှ အတည်ပြုပါ။ Confidential, Personal သို့မဟုတ် Restricted
Data ကို Approval မရှိဘဲ Training မလုပ်ပါနှင့်။

## 5. Verification

သက်ဆိုင်ရာ Module အတွက် Count/List/Status မေးခွန်းများဖြင့်စမ်းပြီး—

- Authorized User က ခွင့်ပြုထားသော Data ကိုသာ မြင်ခြင်း။
- Restricted User က Private Record မမြင်ခြင်း။
- Generated SQL/Query သည် Read-only နှင့် Bounded ဖြစ်ခြင်း။
- Answer မမှန်လျှင် Source Data/Training Timestamp ကို ဖော်ပြနိုင်ခြင်း။
- Concurrent Queries အောက်တွင် Acceptable Latency ရှိခြင်း။

တို့ကို စစ်ပါ။ AI response ကို Financial/Legal/HR decision အဖြစ် Human Review
မပါဘဲ တိုက်ရိုက်မသုံးပါနှင့်။

## 6. Maintenance

- Master Data ပြောင်းလဲမှုနှုန်းအလိုက် Weekly/Approved schedule ဖြင့် Update လုပ်ပါ။
- Custom Schema ပြောင်းပြီး Migration အောင်မြင်မှ Schema file Update လုပ်ပါ။
- Module list, Answer quality, API usage/Cost နှင့် Audit Logs ကို ပုံမှန်စစ်ပါ။
- Model/App update ကို Staging တွင် စမ်းပြီးမှ Production Apply လုပ်ပါ။
- Settings/Custom config ကို Secret-safe Backup ထဲ ထည့်ပြီး Restore စမ်းပါ။

Training ကို Peak hour ပြင်ပတွင် run ပြီး Concurrent requests ကန့်သတ်ပါ။

## 7. ပြဿနာဖြေရှင်းခြင်း

### Training/Master Data/Schema Update မအောင်မြင်ခြင်း

1. changAI/Backend Logs ကိုစစ်ပါ။
2. API Credentials, Internet/DNS နှင့် Provider quota စစ်ပါ။
3. Database access နှင့် User/DocType Permissions စစ်ပါ။
4. Required Module install/migrate အောင်မြင်ကြောင်းစစ်ပါ။
5. Record Size ကိုလျှော့၍ Non-production တွင် ထပ်စမ်းပါ။

### `403 PERMISSION_DENIED`

- Project ID မှန်ကြောင်းနှင့် Required API Enable ဖြစ်ကြောင်းစစ်ပါ။
- API activation အချိန်ပေးပြီး Service Account Role/Key status စစ်ပါ။
- Organization Policy/Region restriction ကို Google Cloud Admin နှင့်စစ်ပါ။

### `Service Account Credentials are missing`

Selected Authentication mode က Service Account လို/မလို စစ်ပါ။ လိုပါက Google
Cloud တွင် Least-privilege Service Account ဖန်တီး၍ Approved Secret channel မှ
JSON ထည့်ပါ။

### Model Download မအောင်မြင်ခြင်း

Container မှ Internet/DNS, Disk space, Provider access နှင့် Credentials ကို
စစ်ပြီး Logs အရ ပြင်ဆင်ပါ။

### Region မရခြင်း

Guess မလုပ်ဘဲ Project အတွက် Model ရသော Region ကို Official Model location
list မှစစ်ပြီး `Gemini_location` ပြောင်းပါ။ VPN ဖြင့် Provider policy/Regional
restriction ကို ကျော်ရန် မကြိုးစားပါနှင့်။

## ဆက်စပ် Resources

- [changAI GitHub](https://github.com/ERPGulf/changAI)
- [Google AI Studio](https://aistudio.google.com/)
- [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
- [Frappe Forum](https://discuss.frappe.io/)
