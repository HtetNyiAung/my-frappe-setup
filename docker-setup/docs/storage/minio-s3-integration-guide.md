# Frappe နှင့် MinIO S3 Object Storage ချိတ်ဆက်နည်း

Frappe attachments, PDFs နှင့် files များကို Local container volume အစား
သီးခြား Storage Server ရှိ MinIO S3 Object Storage တွင် သိမ်းရန် လမ်းညွှန်ဖြစ်သည်။

## 1. လိုအပ်ချက်များ

MinIO Server run နေပြီး App Server မှ S3 API Endpoint သို့ network access
ရရမည်။ အောက်ပါတန်ဖိုးများကို Storage Administrator ထံမှ ရယူပါ။

- **S3 API Endpoint** — ဥပမာ `http://<minio-server-ip>:9000`
- **Access Key**
- **Secret Key**
- **Public/Attachment Bucket** — ဥပမာ `app-public`
- **Private Bucket** — Integration က အမှန်တကယ်သုံးခြင်းရှိ/မရှိကို အောက်တွင်
  စစ်ပါ။

Credentials နှင့် IP အစစ်များကို Documentation သို့မဟုတ် Git ထဲ မထည့်ပါနှင့်။

## 2. `.env` Configuration

`.env` မရှိသေးပါက `.env.example` မှကူးပြီး အောက်ပါ Variables များဖြည့်ပါ။

```env
S3_STORAGE_ENABLED=true
S3_ENDPOINT_URL=http://<minio-server-ip>:9000
S3_ACCESS_KEY=<minio-access-key>
S3_SECRET_KEY=<minio-secret-key>
S3_REGION=us-east-1
S3_BUCKET_NAME=app-public
S3_PRIVATE_BUCKET_NAME=app-private
```

Stacks နှစ်ခုလုံးကို Local Docker host တစ်ခုတည်းပေါ်တွင် run သည့် Development
environment အတွက် `S3_ENDPOINT_URL=http://host.docker.internal:9000` သုံးနိုင်သည်။

| `S3_STORAGE_ENABLED` | လုပ်ဆောင်ချက် |
|---|---|
| `false` | Frappe Local storage (`/files`, `/private/files`) ကိုသုံးသည်။ |
| `true` | MinIO ကိုစစ်ပြီး `frappe_s3_attachment` ကို Site တွင် Install/Configure လုပ်သည်။ |

Script သည် `true/false`, `on/off`, `yes/no`, `1/0` ကို လက်ခံပြီး
`true` သို့မဟုတ် `false` အဖြစ် Normalize လုပ်သည်။

## 3. `apps.json` စစ်ခြင်း

`apps.json` တွင် S3 App ပါကြောင်း စစ်ပါ။

```json
{
  "name": "frappe_s3_attachment",
  "url": "https://github.com/zerodhatech/frappe-attachments-s3.git",
  "branch": "master",
  "is_custom": false
}
```

## 4. Setup လုပ်ခြင်း

ပထမဆုံး Site Setup ဆိုလျှင်—

```bash
./setup.sh
```

ရှိပြီးသား Site ၏ Storage configuration ကို ပြောင်းခြင်းဆိုလျှင်—

```bash
./setup.sh --reconfigure
```

Setup သည်—

1. Custom image တွင် `frappe_s3_attachment` ပါကြောင်း စစ်သည်။
2. S3 Enable ဖြစ်ပါက Frappe containers ထဲသို့ `AWS_ENDPOINT_URL` ထည့်သည်။
3. Hook မဖွင့်မီ Endpoint, Credentials နှင့် Bucket ကို `HeadBucket` ဖြင့်
   စစ်သည်။
4. `S3 File Attachment` DocType တွင် Credentials, Bucket နှင့် Region ကို
   သိမ်းသည်။
5. S3 Disable ဖြစ်ပါက Site အသစ်တွင် App ကို မတပ်ဆင်ဘဲ Local file behavior ကို
   ဆက်သုံးသည်။

## 5. ရှိပြီးသား Site ကို Local Storage သို့ ပြန်ပြောင်းခြင်း

`S3_STORAGE_ENABLED=false` သတ်မှတ်ခြင်းသည် S3-backed `File` records မရှိမှသာ
လုံခြုံသည်။ Setup သည် Private handler URLs နှင့် configured Bucket အောက်ရှိ
Public URLs များကို စစ်သည်။ Record ရှိနေပါက S3 App ကိုမဖြုတ်ဘဲ Setup ရပ်မည်။

S3 Disable လုပ်ခြင်းက Existing objects များကို Local storage သို့ အလိုအလျောက်
Download/Migrate မလုပ်ပါ။ Object များကိုရွှေ့ပြီး သက်ဆိုင်ရာ `File` records ကို
မှန်ကန်စွာ Update လုပ်ပြီးမှ Disable လုပ်ပါ။

## 6. Dependency စစ်ခြင်း

Custom image ထဲတွင် `boto3` ကို App dependency အဖြစ် Install လုပ်ထားရမည်။

```bash
docker compose -f pwd-with-apps.yml exec backend \
  /home/frappe/frappe-bench/env/bin/python -c "import boto3; print(boto3.__version__)"
```

မအောင်မြင်ပါက Image ပြန် Build လုပ်ပြီး S3 App dependencies Install
အောင်မြင်ကြောင်း စစ်ပါ။ Container ၏ System Python ထဲသို့ Package ကို Manual
Install မလုပ်ပါနှင့်။

## 7. Configuration သိမ်းသည့်နေရာ

| အချက် | နည်းလမ်း | နေရာ |
|---|---|---|
| MinIO Endpoint | `AWS_ENDPOINT_URL` Environment variable | `docker-compose.override.yml` |
| Access Key / Secret | Setup မှ ရေးသွင်းသည် | `S3 File Attachment` DocType |
| Bucket / Region | Setup မှ ရေးသွင်းသည် | `S3 File Attachment` DocType |

Setup ပြီးလျှင် Desk တွင် **S3 File Attachment** ကိုဖွင့်ပြီး တန်ဖိုးများ
ပြည့်ကြောင်း စစ်နိုင်သည်။ Secret ကို Screenshot သို့မဟုတ် Log ထဲ မဖော်ပြပါနှင့်။

## 8. Upload စမ်းသပ်ခြင်း

1. Frappe Desk သို့ Login ဝင်ပါ။
2. **File List** ကိုဖွင့်ပါ။
3. Document တစ်ခုတွင် PDF/Image/Test file တစ်ခု Upload လုပ်ပါ။
4. MinIO Console ရှိ `S3_BUCKET_NAME` Bucket ကိုဖွင့်ပါ။
5. Uploaded object ရောက်ကြောင်း စစ်ပါ။
6. Public နှင့် Private file နှစ်မျိုးလုံးကို သက်ဆိုင်ရာ User Role များဖြင့်
   Open/Download စမ်းပါ။

## 9. Bucket Model ကန့်သတ်ချက်

လက်ရှိ `frappe_s3_attachment` တွင် `bucket_name` setting တစ်ခုသာရှိပြီး Public
နှင့် Private uploads နှစ်မျိုးလုံးကို ထို Bucket တွင် သိမ်းသည်။
`S3_PRIVATE_BUCKET_NAME` ကို လက်ရှိ App က မသုံးသေးပါ။ ထို့ကြောင့်
`app-public`/`app-private` သည် အမှန်တကယ် Two-Bucket split မဟုတ်သေးပါ။

Permission-sensitive Private attachments ကို Anonymous download ရသော Bucket
ပေါ် မမှီခိုပါနှင့်။ Two-Bucket split အမှန်ရရန် သီးခြား Application integration,
File permission နှင့် Portal compatibility implementation လိုသည်။

## 10. ပြဿနာဖြေရှင်းခြင်း

### `ModuleNotFoundError: No module named 'boto3'`

```bash
./setup.sh --reconfigure --rebuild
docker compose -f pwd-with-apps.yml exec backend \
  /home/frappe/frappe-bench/env/bin/python -c "import boto3; print(boto3.__version__)"
```

### `InvalidAccessKeyId`

App သည် MinIO အစား AWS S3 သို့ ချိတ်နေခြင်းဖြစ်နိုင်သည်။ Endpoint စစ်ပါ။

```bash
docker compose -f pwd-with-apps.yml exec backend printenv AWS_ENDPOINT_URL
```

ရှိပြီးသား Site တွင် Value မရှိပါက `./setup.sh --reconfigure` ဖြင့် Compose
override ကို ပြန်ဖန်တီးပါ။

### `NoSuchBucket` သို့မဟုတ် S3 preflight failure

`S3_BUCKET_NAME` သည် `S3_ENDPOINT_URL` ရှိ MinIO Server တွင် ရှိကြောင်းနှင့်
Credentials က ထို Bucket ကို Access ရကြောင်း စစ်ပါ။ Setup သည် မမှန်သော
Storage configuration ဖြင့် Upload hook မဖွင့်ရန် ရည်ရွယ်ပြီး ရပ်ခြင်းဖြစ်သည်။

### `S3_STORAGE_ENABLED=false` လုပ်၍မရခြင်း

Site တွင် S3-backed `File` records ရှိနေသေးသည်။ Objects နှင့် File URLs ကို
Local storage သို့ စနစ်တကျ Migrate ပြီးမှ ထပ်လုပ်ပါ။

### Desk တွင် S3 Settings မပြခြင်း

```bash
./setup.sh --reconfigure
```

ပြီးလျှင် Cache ရှင်း၍ Browser Hard Refresh လုပ်ပါ။
