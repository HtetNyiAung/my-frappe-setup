# Email Setup (Gmail & Outlook)

Frappe **Email Account** form မှာ tab သုံးခု ရှိပါတယ် — **Details**, **Incoming**, **Outgoing**.

**Password reset / forgot password** အတွက် **Outgoing** tab က အရေးကြီးပါတယ်။ Incoming က mail လက်ခံချင်မှ လိုပါတယ်။

Open: **Setup → Email → Email Account → Add Email Account**

---

## Quick choice

| Goal | Enable Incoming | Enable Outgoing | Tabs to fill |
|------|-----------------|-----------------|--------------|
| Send only (reset password, notifications) | ✗ | ✓ | **Details** + **Outgoing** |
| Send and receive email in Frappe | ✓ | ✓ | **Details** + **Incoming** + **Outgoing** |

---

## Part 1 — Gmail (`@gmail.com` or Google Workspace)

### 1.1 Before you fill the form

1. Google account မှာ **2-Step Verification** ဖွင့်ပါ။
2. [Google App Passwords](https://myaccount.google.com/apppasswords) မှာ app password ဖန်တီးပါ (name: `Frappe LMS`).
3. 16-character password ကို copy လုပ်ပါ — Frappe **Password** field မှာ **ဒီ password** သုံးပါ (Gmail login password **မသုံးပါ**)။

### 1.2 Tab: Details

| Field | Fill with |
|-------|-----------|
| **Email Address** * | Your Gmail address (example: `hdlp.support@gmail.com`) |
| **Email Account Name** | Short label (example: `Support`) — auto-filled from email |
| **Service** | Select **Gmail** if available (may auto-fill servers) |
| **Domain** | Leave empty |
| **Enable Incoming** | ✓ only if you want Frappe to **receive** mail |
| **Enable Outgoing** | ✓ **Required** for password reset / notifications |
| **Authentication → Method** | **Basic** |
| **Password** | Google **App Password** (16 characters) |
| **Use different Email ID** | ✗ leave unchecked |
| **Awaiting password** | ✗ leave unchecked |
| **Use ASCII encoding for password** | ✗ leave unchecked |

### 1.3 Tab: Incoming (only if Enable Incoming is ✓)

| Field | Fill with |
|-------|-----------|
| **Default Incoming** | ✓ if this is your main inbox for replies |
| **Attachment Limit (MB)** | `25` (default) |
| **Use IMAP** | ✓ |
| **Use SSL** | ✓ |
| **Incoming Server** | `imap.gmail.com` |
| **Port** | `993` |
| **Append To** | Optional (link mail to Lead, Issue, etc.) |
| **Notify if unreplied** | Optional |

Do **not** use POP unless you know you need it. IMAP + SSL + port `993` is standard for Gmail.

### 1.4 Tab: Outgoing (required for send)

| Field | Fill with |
|-------|-----------|
| **Default Outgoing** | ✓ **Required** — system mail sends from this account |
| **Always use this email address as sender address** | ✓ recommended |
| **Always use this name as sender name** | Optional |
| **Send unsubscribe message in email** | Default (usually ✓) |
| **Track Email Status** | Default (usually ✓) |
| **Use TLS** | ✓ |
| **Use SSL** | ✗ leave unchecked (port 587 uses TLS, not SSL) |
| **Outgoing Server** | `smtp.gmail.com` |
| **Port** | `587` |
| **Disable SMTP server authentication** | ✗ leave unchecked |
| **Delivery Status Notification Type** | Leave empty |
| **Always BCC Address** | Leave empty |

### 1.5 Save and test

1. Click **Save**.
2. On the same form: **Send Test Email** → your mailbox → send.
3. Check inbox and spam.

### 1.6 Gmail errors

| Error | Fix |
|-------|-----|
| `535 Username and Password not accepted` | Use App Password, not Gmail login password |
| Connection timeout on `587` | Server firewall must allow outbound port `587` |
| Mail in spam | Normal for new senders; set up SPF/DKIM in Google Workspace |

---

## Part 2 — Outlook / Microsoft 365

Work/school: `@yourdomain.com` on Microsoft 365.  
Personal: `@outlook.com`, `@hotmail.com`.

### 2.1 Before you fill the form

**Microsoft 365 (work / school)**

1. Mailbox ရွေးပါ (example: `noreply@yourdomain.com`).
2. **Authenticated SMTP** ဖွင့်ထားရပါမယ်:
   - M365 admin → **Users** → user → **Mail** → **Manage email apps** → **Authenticated SMTP** ✓
3. MFA ရှိရင် **app password** သုံးပါ။

**Personal Outlook.com**

1. Full email သုံးပါ။
2. MFA ရှိရင် [Microsoft account security](https://account.microsoft.com/security) မှာ app password ဖန်တီးပါ။

### 2.2 Tab: Details

| Field | Fill with |
|-------|-----------|
| **Email Address** * | Your Outlook address (example: `support@yourdomain.com`) |
| **Email Account Name** | Short label (example: `Support`) |
| **Service** | Select **Outlook.com** or **Office 365** if available |
| **Domain** | Leave empty (or your org domain if prompted) |
| **Enable Incoming** | ✓ only if you want Frappe to **receive** mail |
| **Enable Outgoing** | ✓ **Required** |
| **Authentication → Method** | **Basic** |
| **Password** | Mailbox password or Microsoft **app password** |
| **Use different Email ID** | ✗ leave unchecked |
| **Awaiting password** | ✗ leave unchecked |

### 2.3 Tab: Incoming (only if Enable Incoming is ✓)

**Microsoft 365 / Exchange Online**

| Field | Fill with |
|-------|-----------|
| **Default Incoming** | ✓ if main inbox |
| **Attachment Limit (MB)** | `25` |
| **Use IMAP** | ✓ |
| **Use SSL** | ✓ |
| **Incoming Server** | `outlook.office365.com` |
| **Port** | `993` |

**Personal Outlook.com / Hotmail**

| Field | Fill with |
|-------|-----------|
| **Incoming Server** | `outlook.office365.com` |
| **Port** | `993` |
| **Use IMAP** | ✓ |
| **Use SSL** | ✓ |

### 2.4 Tab: Outgoing (required for send)

**Microsoft 365 / Exchange Online**

| Field | Fill with |
|-------|-----------|
| **Default Outgoing** | ✓ **Required** |
| **Always use this email address as sender address** | ✓ recommended |
| **Use TLS** | ✓ |
| **Use SSL** | ✗ leave unchecked |
| **Outgoing Server** | `smtp.office365.com` |
| **Port** | `587` |
| **Disable SMTP server authentication** | ✗ leave unchecked |

**Personal Outlook.com / Hotmail**

| Field | Fill with |
|-------|-----------|
| **Outgoing Server** | `smtp-mail.outlook.com` |
| **Port** | `587` |
| **Use TLS** | ✓ |
| **Use SSL** | ✗ leave unchecked |
| Other outgoing fields | Same as M365 table above |

Use port **587** + **Use TLS**. Port `465` + SSL is usually not needed for Office 365.

### 2.5 Save and test

1. Click **Save**.
2. **Send Test Email** to yourself.
3. Check inbox and spam.

### 2.6 Outlook errors

| Error | Fix |
|-------|-----|
| `535 Authentication failed` | Wrong password; enable Authenticated SMTP; use app password |
| `SmtpClientAuthentication is disabled` | Enable SMTP AUTH per mailbox in M365 admin |
| Personal account blocked | Use app password; server `smtp-mail.outlook.com` |

---

## Gmail vs Outlook — server summary

| | Gmail | Outlook M365 | Outlook personal |
|---|--------|----------------|------------------|
| **Incoming server** | `imap.gmail.com` | `outlook.office365.com` | `outlook.office365.com` |
| **Incoming port** | `993` (IMAP + SSL) | `993` (IMAP + SSL) | `993` (IMAP + SSL) |
| **Outgoing server** | `smtp.gmail.com` | `smtp.office365.com` | `smtp-mail.outlook.com` |
| **Outgoing port** | `587` (TLS) | `587` (TLS) | `587` (TLS) |
| **Password** | Google App Password | Mailbox / app password | Mailbox / app password |

---

## After setup (both providers)

### System settings

1. **Setup → Settings → System Settings**
2. **Email Footer Address** — support or admin email
3. **Time Zone** — `Asia/Yangon` if Myanmar
4. Save

### User email (forgot password)

1. **Setup → Users** → open user
2. **Email** must be a real address that receives mail

### Test forgot password

1. Log out → login page → **Forgot Password**
2. Enter user email from **Users**
3. Check mailbox (and spam)

### Email queue (if mail delayed)

**Setup → Email → Email Queue** → open **Error** rows for the message.

```bash
cd docker-setup
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend \
  bench --site frontend execute frappe.email.queue.flush
```

## Production: `PUBLIC_URL`

Reset links use `.env`:

```env
PUBLIC_URL=https://lms.yourdomain.com
```

After change:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml restart backend frontend
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend \
  bench --site frontend clear-cache
```

## Verify default outgoing

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend \
  bench --site frontend execute "frappe.db.get_value('Email Account', {'default_outgoing': 1}, 'email_id')"
```

## Related guides

- [setup.md](./setup.md)
- [checklists.md](./checklists.md)
- [keycloak-frappe-setup-guide.md](./keycloak-frappe-setup-guide.md)

## Myanmar quick notes

- Form tab **သုံးခု** — **Details** (email + password), **Incoming** (လက်ခံချင်မှ), **Outgoing** (ပို့ချင်ရင် — reset password အတွက် လိုပါတယ်)။
- **Gmail** = App Password + `smtp.gmail.com:587` (TLS) + `imap.gmail.com:993` (SSL)။
- **Outlook M365** = `smtp.office365.com:587` + `outlook.office365.com:993` + Authenticated SMTP ဖွင့်ထားရမယ်။
- **Outlook personal** = outgoing `smtp-mail.outlook.com:587`။
- User မှာ **Email** မှန်မှ **Forgot Password** mail ရပါမယ်။
