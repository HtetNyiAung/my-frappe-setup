# Email Setup လမ်းညွှန် (Gmail နှင့် Outlook)

Frappe **Email Account** Form တွင် **Details**, **Incoming**, **Outgoing** Tabs
သုံးခုရှိသည်။ Password Reset/Notifications ပို့ရန် **Outgoing** လိုပြီး Email
လက်ခံမှသာ **Incoming** လိုသည်။

```text
Setup → Email → Email Account → Add Email Account
```

| လိုအပ်ချက် | Enable Incoming | Enable Outgoing | ဖြည့်ရန် Tabs |
|---|---:|---:|---|
| Send only | မဖွင့် | ဖွင့် | **Details**, **Outgoing** |
| Send and Receive | ဖွင့် | ဖွင့် | Tabs သုံးခုလုံး |

## 1. Gmail / Google Workspace

### မစတင်မီ

1. Google account တွင် **2-Step Verification** ဖွင့်ပါ။
2. [Google App Passwords](https://myaccount.google.com/apppasswords) တွင် App
   Password ဖန်တီးပါ။
3. Frappe **Password** Field တွင် Gmail Login password မဟုတ်ဘဲ App Password
   ကိုသုံးပါ။ Secret ကို Documentation/Screenshot/Git ထဲ မထည့်ပါနှင့်။

### **Details** Tab

| Field | Value |
|---|---|
| **Email Address** | Mailbox address |
| **Email Account Name** | ဖတ်ရလွယ်သော Label |
| **Service** | ရှိပါက **Gmail** |
| **Domain** | Blank |
| **Enable Incoming** | Mail လက်ခံလိုမှ Enable |
| **Enable Outgoing** | Password Reset/Notification အတွက် Enable |
| **Authentication → Method** | **Basic** |
| **Password** | Google App Password |
| **Use different Email ID** | ပုံမှန်အားဖြင့် Off |
| **Awaiting password** | Off |
| **Use ASCII encoding for password** | Off |

### **Incoming** Tab

| Field | Value |
|---|---|
| **Default Incoming** | Main Inbox ဖြစ်မှ Enable |
| **Attachment Limit (MB)** | `25` သို့မဟုတ် Approved limit |
| **Use IMAP** | Enable |
| **Use SSL** | Enable |
| **Incoming Server** | `imap.gmail.com` |
| **Port** | `993` |

### **Outgoing** Tab

| Field | Value |
|---|---|
| **Default Outgoing** | Enable |
| **Always use this email address as sender address** | Recommended Enable |
| **Use TLS** | Enable |
| **Use SSL** | Off |
| **Outgoing Server** | `smtp.gmail.com` |
| **Port** | `587` |
| **Disable SMTP server authentication** | Off |

**Save → Send Test Email** ကိုနှိပ်ပြီး Inbox/Spam စစ်ပါ။

| Error | ဖြေရှင်းရန် |
|---|---|
| `535 Username and Password not accepted` | Gmail Login password အစား App Password သုံးပါ။ |
| Port `587` timeout | Server Outbound Firewall/Provider restriction စစ်ပါ။ |
| Spam ထဲရောက်ခြင်း | Google Workspace SPF/DKIM/DMARC နှင့် Sender reputation စစ်ပါ။ |

## 2. Outlook / Microsoft 365

### မစတင်မီ

- Microsoft 365 Admin တွင် Mailbox ၏ **Authenticated SMTP** ကို ခွင့်ပြုထားရမည်။
- MFA သုံးပါက Tenant policy ခွင့်ပြုသော App Password သို့မဟုတ် Supported OAuth
  method ကိုသုံးပါ။ Organization က Basic SMTP AUTH ပိတ်ထားပါက Security policy
  ကိုမကျော်ဘဲ Microsoft 365 Administrator နှင့် Supported authentication ကို
  ရွေးပါ။

### **Details** Tab

| Field | Value |
|---|---|
| **Email Address** | Outlook/Microsoft 365 Mailbox address |
| **Email Account Name** | ဖတ်ရလွယ်သော Label |
| **Service** | ရှိပါက **Outlook.com** သို့မဟုတ် **Office 365** |
| **Enable Incoming** | Mail လက်ခံလိုမှ Enable |
| **Enable Outgoing** | Enable |
| **Authentication → Method** | Tenant policy နှင့်ကိုက်သော Method |
| **Password** | Mailbox/App Password (policy ခွင့်ပြုမှ) |

### **Incoming** Tab

| Field | Microsoft 365 / Outlook.com |
|---|---|
| **Use IMAP** | Enable |
| **Use SSL** | Enable |
| **Incoming Server** | `outlook.office365.com` |
| **Port** | `993` |

### **Outgoing** Tab

| Field | Microsoft 365 | Personal Outlook.com |
|---|---|---|
| **Default Outgoing** | Enable | Enable |
| **Use TLS** | Enable | Enable |
| **Use SSL** | Off | Off |
| **Outgoing Server** | `smtp.office365.com` | `smtp-mail.outlook.com` |
| **Port** | `587` | `587` |
| **Disable SMTP server authentication** | Off | Off |

**Save → Send Test Email** ဖြင့်စမ်းပါ။

| Error | ဖြေရှင်းရန် |
|---|---|
| `535 Authentication failed` | Credential, MFA/App Password နှင့် SMTP AUTH policy စစ်ပါ။ |
| `SmtpClientAuthentication is disabled` | M365 Admin က Mailbox/Tenant policy စစ်ရမည်။ |
| Personal account blocked | App Password နှင့် `smtp-mail.outlook.com` စစ်ပါ။ |

## 3. Server အကျဉ်းချုပ်

| | Gmail | Microsoft 365 | Personal Outlook |
|---|---|---|---|
| Incoming | `imap.gmail.com:993` SSL | `outlook.office365.com:993` SSL | `outlook.office365.com:993` SSL |
| Outgoing | `smtp.gmail.com:587` TLS | `smtp.office365.com:587` TLS | `smtp-mail.outlook.com:587` TLS |

## 4. Setup ပြီးနောက်

1. **System Settings** တွင် **Email Footer Address** နှင့် **Time Zone**
   (`Asia/Yangon` လိုအပ်ပါက) ပြင်ပါ။
2. **Users** ရှိ User Email သည် Mail လက်ခံနိုင်သော Address မှန်ဖြစ်ရမည်။
3. Logout → **Forgot Password** ဖြင့် Reset Email စမ်းပါ။
4. Mail နောက်ကျပါက **Email Queue** ရှိ **Error** Rows ကိုစစ်ပါ။

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend \
  bench --site frontend execute frappe.email.queue.flush
```

`frontend` ကို Site အမည်အမှန်ဖြင့် ပြောင်းပါ။ Password Reset Link မှန်ရန်—

```env
PUBLIC_URL=https://lms.example.com
```

Value ပြောင်းပြီးနောက် ပုံမှန်အားဖြင့် `./setup.sh --reconfigure` သုံးပါ။ Manual
operation လိုပါက—

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml restart backend frontend
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend \
  bench --site frontend clear-cache
```

Default Outgoing account စစ်ရန်—

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend \
  bench --site frontend execute "frappe.db.get_value('Email Account', {'default_outgoing': 1}, 'email_id')"
```

## ဆက်စပ်လမ်းညွှန်များ

- [Setup](../setup/setup.md)
- [Hosting Checklists](../setup/checklists.md)
- [Keycloak SSO](keycloak-frappe-setup-guide.md)
