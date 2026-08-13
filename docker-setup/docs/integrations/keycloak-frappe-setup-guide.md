# Keycloak နှင့် Frappe SSO ချိတ်ဆက်နည်း

Keycloak Realm/Client အသစ်ဖန်တီးပြီး Frappe **Social Login Key** နှင့်
OAuth2/OpenID Connect (OIDC) SSO ချိတ်ရန် လမ်းညွှန်ဖြစ်သည်။ Keycloak/Frappe
Version အလိုက် URL prefix နှင့် UI ပြောင်းနိုင်သောကြောင့် Realm ၏
**OpenID Endpoint Configuration** မှ Endpoint အမှန်ကို ကူးသုံးပါ။ Production
တွင် HTTP/`localhost` အစား Public HTTPS URLs သုံးရမည်။

## 1. Keycloak Configuration

### Realm အသစ်ဖန်တီးခြင်း

1. Keycloak Admin Console သို့ Admin account ဖြင့် Login ဝင်ပါ။
2. **Master → Create Realm** နှိပ်ပါ။
3. Realm name ဥပမာ `frappe-realm` ထည့်ပြီး **Create** လုပ်ပါ။

`master` Realm သည် Keycloak Administration အတွက်ဖြစ်သောကြောင့် Application
Users/Clients ကို Dedicated Realm တွင်ထားပါ။ Default Admin password မသုံးပါနှင့်။

### Frappe Client ဖန်တီးခြင်း

1. **Clients → Create Client** ကိုဖွင့်ပါ။
2. **Client type = OpenID Connect**, **Client ID = frappe-client** သတ်မှတ်ပါ။
3. **Client authentication = On**, **Standard flow = On** လုပ်ပါ။
4. **Valid redirect URIs** တွင် Frappe Callback URL အတိအကျထည့်ပါ။
5. **Web origins** တွင် Frappe Public Origin ထည့်ပါ။ Wildcard ကို Production
   တွင် မသုံးပါနှင့်။

```text
Valid redirect URI:
https://<frappe-domain>/api/method/frappe.integrations.oauth2_logins.custom/keycloak

Web origin:
https://<frappe-domain>
```

Frappe Provider Name/Slug ပြောင်းထားပါက Callback URL နောက်ဆုံး slug ကို
ကိုက်ညီအောင် ပြင်ပါ။ **Credentials** Tab မှ **Client Secret** ကို Secret storage
တွင်သိမ်းပြီး Git/Screenshot/Documentation ထဲ မထည့်ပါနှင့်။

### OIDC Endpoints ရယူခြင်း

**Realm Settings → OpenID Endpoint Configuration** ကိုဖွင့်ပြီး Discovery JSON
မှ `authorization_endpoint`, `token_endpoint`, `userinfo_endpoint`, `issuer`
တို့ကို ကူးပါ။ ပုံမှန်ပုံစံ—

```text
Browser-facing Authorize URL:
https://<keycloak-domain>/realms/<realm>/protocol/openid-connect/auth

Server-facing Token URL:
http://<keycloak-service>:8080/realms/<realm>/protocol/openid-connect/token

Server-facing Userinfo URL:
http://<keycloak-service>:8080/realms/<realm>/protocol/openid-connect/userinfo
```

Keycloak Installation တချို့တွင် `/auth` prefix ပါနိုင်သည်။ Guess မလုပ်ဘဲ
Discovery JSON ကိုသုံးပါ။ Browser-facing URL ကို User Browser မှရောက်နိုင်ရပြီး
Server-facing URL ကို Frappe container မှရောက်နိုင်ရမည်။ Issuer/Hostname policy
ကြောင့် Public URL တစ်ခုတည်းလိုပါက Container မှလည်း ထို Domain ကို Resolve/
Access ရအောင် ပြင်ပါ။

### Signup နှင့် Test User

Self-registration လိုအပ်မှသာ **Realm Settings → Login** တွင် **User
registration**, **Forgot password**, **Remember me** တို့ကို Policy အတိုင်း
ဖွင့်ပါ။ Forgot Password အတွက် Keycloak Email settings လည်း လိုသည်။

**Users → Add user** တွင် Test User ဖန်တီး၍ Email ထည့်ပြီး လိုအပ်ပါက
**Email verified = On** လုပ်ပါ။ **Credentials → Set password** တွင် Test
password သတ်မှတ်ပါ။ Production User အတွက် နမူနာ/Weak password မသုံးပါနှင့်။

## 2. Frappe Configuration

### Social Login Key

1. Frappe ကို Local Administrator account ဖြင့် Login ဝင်ပါ။
2. **Social Login Key → Add Social Login Key** ကိုဖွင့်ပါ။
3. Editable Custom endpoints လိုပါက **Social Login Provider = Custom** ရွေးပါ။

Basic fields—

| Field | Value |
|---|---|
| **Social Login Provider** | `Custom` |
| **Provider Name** | `Keycloak` |
| **Client ID** | `frappe-client` |
| **Client Secret** | Keycloak Client Secret |
| **Base URL** | Discovery document ၏ Realm/Issuer Base URL |
| **Enable Social Login** | Enable |

Endpoint fields—

| Field | Value |
|---|---|
| **Authorize URL** | Discovery `authorization_endpoint` (Browser reachable) |
| **Access Token URL** | Discovery `token_endpoint` (Frappe reachable) |
| **Redirect URL** | `https://<frappe-domain>/api/method/frappe.integrations.oauth2_logins.custom/keycloak` |
| **API Endpoint** | Discovery `userinfo_endpoint` |

Profile mapping—

```json
{"response_type":"code","scope":"openid profile email"}
```

**User ID Property** ကို `sub` သို့မဟုတ် Organization policy အရ stable/verified
`email` သတ်မှတ်ပါ။ Email claim ပါ/မပါနှင့် Verification status ကို စစ်ပါ။
Login တိုင်း Credential ပြန်တောင်းလိုမှ `"prompt":"login"` ထည့်နိုင်သော်လည်း
SSO User experience အပေါ် သက်ရောက်မှုရှိသောကြောင့် ရည်ရွယ်ချက်ရှိရှိသာသုံးပါ။

### Signup Policy

Frappe က New SSO User auto-create လုပ်ရန်လိုပါက **Website Settings → Sign Up
and Login** ရှိ **Disable Signup** ကို Policy အရပိတ်ပါ။ **Verify Sign Up** နှင့်
**Wait for Administrator Verification** ကို ပိတ်ခြင်းသည် User ကို ချက်ချင်း
Access ပေးနိုင်သဖြင့် Security/Approval requirement နှင့်ကိုက်ညီမှသာလုပ်ပါ။

### Login စမ်းသပ်ခြင်း

1. Frappe မှ Logout လုပ်ပါ။
2. **Login with Keycloak** ကိုနှိပ်ပါ။
3. Keycloak Test User ဖြင့် Login ဝင်ပါ။
4. Callback အောင်မြင်ပြီး Expected Portal/Desk သို့ရောက်ကြောင်းစစ်ပါ။
5. Disabled/Unauthorized User, Logout, Password Reset နှင့် Error flows ကိုလည်း
   စမ်းပါ။ Emergency Local Administrator account တစ်ခုထားပါ။

## 3. Roles နှင့် Groups

Keycloak Group Claim ပါလာရုံဖြင့် Frappe Role အလိုအလျောက် Sync ဖြစ်မည်ဟု
မယူဆပါနှင့်။ မိမိ Frappe Version/Custom Integration က Claim ကို ယုံကြည်စွာ
Validate/Map လုပ်ပေးကြောင်း Test ဖြင့်အတည်ပြုရမည်။ UI ရှိ **Social Login Key
Roles** Table သည် New User အတွက် Default Role သတ်မှတ်ရာတွင် အသုံးဝင်နိုင်သည်။

| Frappe Role | Access |
|---|---|
| `Customer`, `Website User` | Portal-only |
| `Employee`, `Employee Self Service` | Configured Permissions အတိုင်း Desk access |
| `System Manager` | Full Administrative access; ပုံမှန် SSO User မပေးရ |

Portal-only User က `/desk` ဝင်မရခြင်းသည် Expected behavior ဖြစ်နိုင်သည်။
`System Manager` ကို Login error ပြင်ရန် shortcut အဖြစ် မပေးပါနှင့်။

### Keycloak Group Claim ထည့်ခြင်း

1. **Groups** တွင် Frappe Roles နှင့် တိကျစွာကိုက်ညီသော Approved group names
   ဖန်တီးပါ။ Names သည် Case-sensitive ဖြစ်သည်။
2. New Users အတွက် Least-privilege Default Group သတ်မှတ်ပါ။
3. Existing Users ကို လိုအပ်သော Groups များတွင်သာ ထည့်ပါ။
4. **Clients → frappe-client → Client scopes → dedicated scope** တွင်
   **Group Membership** Mapper ထည့်ပါ။

| Mapper Field | Value |
|---|---|
| **Name** | `groups` |
| **Token Claim Name** | `roles` |
| **Full group path** | Off |
| **Add to ID token** | On |
| **Add to access token** | On |
| **Add to userinfo** | On |

**Full group path = On** ဖြစ်ပါက `/Customer` ကဲ့သို့ Claim ရပြီး `Customer`
Role နှင့် မတူတော့ပါ။ Token/Userinfo response ကို Secret ဖုံးကွယ်ထားသော Test
environment တွင်စစ်ပါ။

### Fallback Role

Frappe **Portal Settings → Default Role** တွင် Least-privilege Portal Role
သတ်မှတ်နိုင်သည်။ ဒီ Fallback သည် Keycloak Role synchronization ကို အစားမထိုးပါ။

## 4. Google Identity Provider (Optional)

1. Google Cloud Console တွင် Web OAuth Client ဖန်တီးပါ။
2. Keycloak ကပြသော Broker Redirect URI ကို Google **Authorized redirect URIs**
   ထဲ အတိအကျထည့်ပါ။

```text
https://<keycloak-domain>/realms/<realm>/broker/google/endpoint
```

3. Keycloak **Identity Providers → Google** တွင် Client ID/Secret ထည့်ပါ။
4. Test Users အနည်းငယ်ဖြင့် Account linking, Email verification, Logout နှင့်
   Role assignment စမ်းပြီးမှ Production ဖွင့်ပါ။

## 5. Custom Role Sync (Optional)

Simple Default Role မလုံလောက်ပါက Server Script ထက် Version-controlled Custom
Frappe App တွင် Server-side OAuth hook/service ရေးရန် အကြံပြုသည်။ Remote Role
name ကို တိုက်ရိုက်ယုံ၍ Permission ပေးမထားဘဲ—

- Trusted Issuer/Audience/Client ကို Validate လုပ်ပါ။
- Approved Claim-to-Role Allowlist သုံးပါ။
- Unknown/Admin Roles ကို Reject လုပ်ပါ။
- Role change Audit Log ထားပါ။
- Authorized/Unauthorized Tests ရေးပါ။

Server Scripts ကို ရည်ရွယ်ချက်ရှိရှိ Enable လုပ်ရန်လိုပါက Site တစ်ခုတည်းအတွက်—

```bash
docker compose exec -T backend bench --site frontend set-config server_script_enabled 1
docker compose exec -T backend bench --site frontend clear-cache
docker compose restart backend
```

`frontend` ကို Site အမည်အမှန်ဖြင့်ပြောင်းပါ။ OAuth callback အတွင်း အသုံးပြုမည့်
`social_login_data` နှင့် Hook timing သည် Frappe Version အလိုက်တည်ငြိမ်ကြောင်း
စမ်းသပ်ခြင်းမရှိဘဲ Production Server Script မထည့်ပါနှင့်။

## 6. ပြဿနာဖြေရှင်းခြင်း

| ပြဿနာ | စစ်ဆေးရန် |
|---|---|
| `redirect_uri_mismatch` | Keycloak Valid Redirect URI နှင့် Frappe Callback URL အက္ခရာတိုင်းတူရမည်။ |
| Token request မရ | Frappe container မှ Token URL/DNS/Port ရောက်နိုင်မှု စစ်ပါ။ |
| Issuer error | Discovery `issuer`, Public hostname နှင့် Frappe config ကိုက်ညီမှု စစ်ပါ။ |
| `403 Not Permitted` | User type, Assigned Roles နှင့် Server-side Permissions စစ်ပါ။ |
| `/desk` မဝင်နိုင် | Portal-only Role ဖြစ်/မဖြစ် စစ်ပါ။ |
| Role claim မပေါ် | Mapper, `roles` Claim name, Full group path နှင့် User group membership စစ်ပါ။ |
| Login loop | Public URLs, Proxy forwarded headers, Cookies, HTTPS နှင့် Clock sync စစ်ပါ။ |

ပြဿနာဖြေရှင်းရန် `System Manager` ပေးခြင်း၊ Signup verification ပိတ်ခြင်း သို့မဟုတ်
Wildcard Redirect URI သုံးခြင်းကို Shortcut အဖြစ် မလုပ်ပါနှင့်။
