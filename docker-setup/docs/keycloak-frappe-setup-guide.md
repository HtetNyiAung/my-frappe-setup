# Keycloak + Frappe (ERPNext) SSO Integration Guide

This guide walks you through setting up a fresh Keycloak instance, creating a completely new Realm (recommended over using the default _Master_ realm), creating an OAuth2 client, and then configuring ERPNext (Frappe) so that users can log in using Keycloak.

---

## Part 1: Keycloak Configuration

Since you just wiped the database, Keycloak is clean. Follow these steps to prepare your authentication server.

### 1. Log into Keycloak
1. Go to **http://localhost:8686/auth/admin**
2. Login with your admin credentials:
   - **Username**: \`admin\`
   - **Password**: \`admin\`

### 2. Create a New Realm
> [!IMPORTANT]
> **Why not Master?** The \`master\` realm is strictly for Keycloak administration. Dedicated applications (like your Frappe setup) should always exist inside their own realms so the user permissions are completely isolated.

1. Look at the top-left corner where it says **Master** with a dropdown arrow. Click the dropdown.
2. Click **Create Realm**.
3. **Realm name**: \`frappe-realm\` (You can name it anything, but we will use this name for the rest of the guide).
4. Click **Create**.

### 3. Create a New Client (For Frappe)
Now that you are inside your new \`frappe-realm\`, we need to tell Keycloak about Frappe so it accepts authentication requests.

1. On the left sidebar menu, go to **Clients**.
2. Click **Create Client**.
3. In the **General Settings** tab:
   - **Client type**: \`OpenID Connect\`
   - **Client ID**: \`frappe-client\` (Keep this in mind, you need it for Frappe).
   - Click **Next**.
4. In the **Capability config** tab:
   - **Client authentication**: Toggle this **ON** (This forces Keycloak to generate a Client Secret).
   - **Authorization**: Keep toggled OFF unless you are doing complex permission management mappings.
   - For **Authentication flow**, ensure **Standard flow** is checked.
   - Click **Next**.
5. In the **Login settings** tab:
   - **Valid redirect URIs**: \`http://localhost:8787/api/method/frappe.integrations.oauth2_logins.custom/*\` (Replace \`localhost:8787\` if your ERPNext address is different, but based on your compose file, it is \`localhost:8787\`).
   - **Web origins**: \`http://localhost:8787\` (Crucial for CORS).
   - Click **Save**.

### 4. Copy Your Missing Credentials
Your client is now created. We need its specific credentials for Frappe.

1. Inside your new \`frappe-client\` configurations, navigate to the **Credentials** tab at the top.
2. Locate the **Client Secret**.
3. Copy the secret ID. You'll need it shortly.

---

### 5. Obtain Your Keycloak Endpoints
Frappe will need to know *where* to direct the browser to log in, and *where* to fetch tokens.

Go to **Realm Settings** (on the left menu below your Realm name). At the very top under "General", look for "Endpoints", and click **OpenID Endpoint Configuration**. A JSON page will pop up, which will show you exact addresses, but they essentially follow this formula:

- **Base URL**: \`http://keycloak:8080/auth/realms/frappe-realm\` 
  > *(Why not \`localhost:8686\`? Because the Frappe container will be talking to the Keycloak container directly across their shared Docker network! So \`keycloak:8080\` is the actual internal path).*
- **Authorization Endpoint**: \`http://localhost:8686/auth/realms/frappe-realm/protocol/openid-connect/auth\` 
  > *(The authorization explicitly happens on the user's browser, so it MUST be the public-facing localhost URL).*
- **Token Endpoint**: \`http://keycloak:8080/auth/realms/frappe-realm/protocol/openid-connect/token\`
- **Userinfo Endpoint**: \`http://keycloak:8080/auth/realms/frappe-realm/protocol/openid-connect/userinfo\`

---

### 6. Set Up User Features (Signup, Forgot Password)
By default, Keycloak does not allow users to register themselves.
1. Go to **Realm Settings** > **Login** tab.
2. Toggle **User registration** to **ON**.
3. Toggle **Forgot password** to **ON**.
4. Toggle **Remember me** to **ON**.
5. Click **Save**.

### 7. Add a Test User in Keycloak
1. Go to **Users** in the left menu.
2. Click **Add user**.
3. **Username**: \`testuser\`
4. **Email**: \`testuser@example.com\`
5. **Email verified**: Toggle to ON (Frappe requires an email).
6. Click **Create**.
7. Once the user is made, go to the **Credentials** tab for that user.
8. Click **Set password**.
9. Set a password (e.g., \`testpass\`) and switch **Temporary** to **OFF**. Look for the confirmation to save.

---
---

## Part 2: Frappe / ERPNext Configuration

Now we set up the "Social Login Keys" in Frappe.

### 1. Enable Social Logins in ERPNext
1. Open up ERPNext at **http://localhost:8787** and log in manually the first time as the Administrator.
2. In the global search bar, type **Social Login Key** and hit enter (this opens the Social Login Key List).
3. Click **Add Social Login Key**.

### 2. Configure the Keycloak Integration
Fill in the form very carefully using the credentials we created in Part 1.

> [!IMPORTANT]  
> **CRITICAL FIX**: In the **Social Login Provider** dropdown at the very top, you MUST select **Custom**. Do NOT select "Keycloak" if it appears in the dropdown, as Frappe will lock the Endpoint URL fields and you won't be able to edit them!

#### Basic Info
- **Social Login Provider**: \`Custom\`
- **Provider Name**: \`Keycloak\` (This is just a label, type "Keycloak" here so the button says "Login with Keycloak")
- **Client ID**: \`frappe-client\`
- **Client Secret**: *(Paste the long string you copied from the client Credentials tab)*
- **Base URL**: \`http://keycloak:8080/auth/realms/frappe-realm\`  
- **Enable Social Login**: Check the box ✅

#### Endpoint URLs
- **Authorize URL**: \`http://localhost:8686/auth/realms/frappe-realm/protocol/openid-connect/auth\` (User's browser does this)
- **Access Token URL**: \`http://keycloak:8080/auth/realms/frappe-realm/protocol/openid-connect/token\` (Server does this internally)
- **Redirect URL**: \`http://localhost:8787/api/method/frappe.integrations.oauth2_logins.custom/keycloak\` (Make sure the final slug matches your Provider Name lowercase, e.g. \`keycloak\`)
- **API Endpoint**: \`http://keycloak:8080/auth/realms/frappe-realm/protocol/openid-connect/userinfo\` (This is CRITICAL: Frappe fetches the test user's email from here!)

#### Field Mapping (Under Profile Property)
We need to map exactly what Keycloak sends to what Frappe expects.

- **Auth url data**: \`{"response_type": "code", "scope": "openid profile email", "prompt": "login"}\`
  > *(Adding \`"prompt": "login"\` is a crucial trick! It forces Keycloak to ask for the password every time you click the button, fixing the issue where logging out of Frappe didn't log you out of Keycloak).*
- **User ID Property**: \`sub\` (or you can use \`email\` if you want them strictly bound by email)

---

### 3. Fixing "Not Permitted" Error (Role Assignment)
When a new user signs up via Keycloak/Google, Frappe automatically creates a new User account, but assigns it the **Website User** role by default. This role is not allowed to access the Desk (Dashboard), which results in a **"Not Permitted"** error.

**To fix this automatically:**
1. Scroll to the very bottom of the **Social Login Key** page for Keycloak.
2. Look for the **Roles** (or **Social Login Key Roles**) table.
3. Click the **"Add Row"** button.
4. Select a role that allows Desk access, such as **Employee** or **System Manager** (careful: System Manager gives full access!).
5. Click **Save**.

Now, when a new user signs up via Keycloak, they will be given the **Employee** role automatically and can access the dashboard.

---

### 4. Enable Signups in Frappe (ERPNext)
If you see a **"Signup is Disabled"** error when trying to use Keycloak, you must enable it in Frappe:
1. Search for **Website Settings** in the Frappe search bar.
2. Under the **Sign Up and Login** section, uncheck the box for **Disable Signup**.
3. Click **Save**.

### 5. Final Keycloak Registration Check
To ensure **Register** and **Forgot Password** work correctly on the Keycloak screen:
1. In Keycloak Admin, go to **Realm Settings** > **Login** tab.
2. Confirm both **User registration** and **Forgot password** are toggled **ON**.
3. Now, when a user clicks "Login with Keycloak" in Frappe, they can use these features!

---

### 6. Save & Test!
1. Click **Save** in the top right.
2. Log out of Frappe.
3. On the ERPNext Login screen, you should now see a bright blue button below the username/password box saying **Login with Keycloak**.
4. Test with a **New User** signup and verify they can see the ERPNext Dashboard!

---

### 7. Bypassing "Administrator Verification" Error
If you see the message **"Please ask your administrator to verify your sign-up"** after a user signs up via Keycloak:

1. Search for **Website Settings** in the Frappe search bar.
2. Scroll to the **Sign Up and Login** section.
3. **Uncheck** these two boxes:
   - [ ] **Verify Sign Up** (This stops Frappe from sending verification emails).
   - [ ] **Wait for Administrator Verification** (This allows users to log in immediately without manual approval).
4. Click **Save**.

---
---

## Part 3: Advanced Integrations

You can configure Google Social Login inside Keycloak so users can log into Frappe using their Gmail accounts.

### Step 1: Obtain Google Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create/Select a Project > **APIs & Services** > **Credentials**.
3. Click **+ CREATE CREDENTIALS** > **OAuth client ID**.
4. Select **Web application**.
5. Under **Authorized redirect URIs**, add the Keycloak broker URL:
   - \`http://localhost:8686/auth/realms/frappe-realm/broker/google/endpoint\`
6. Click **CREATE** and copy the **Client ID** and **Client Secret**.

### Step 2: Configure Google in Keycloak
1. Go to **Identity Providers** > **Add provider...** > **Google**.
2. Paste the **Client ID** and **Client Secret**.
3. Click **Add**.

### Step 3: Test
Now, when users click "Login with Keycloak" on the Frappe login page, they will see a **Google** button on the Keycloak screen to authenticate with their Gmail.

---
---

## Part 4: Keycloak Role Management (Groups → Frappe Roles)

This is the **recommended approach** for assigning roles. No Server Scripts needed — Keycloak Groups are directly mapped to Frappe Roles.

### Understanding Frappe Role Types

> [!IMPORTANT]
> Not all Frappe roles give the same level of access. Choose roles carefully:

| Role | Access Level | Description |
|------|-------------|-------------|
| **Customer** | Portal only | Can access `/me` (profile page), view orders, invoices. **Cannot** access `/desk` (backend dashboard). |
| **Website User** | Portal only | Basic website access. |
| **Employee** | Desk access | Can access `/desk` with limited permissions (HR, leave, attendance). |
| **System Manager** | Full Desk access | **Full admin access** to everything. Use with caution! |
| **Employee Self Service** | Desk access | Limited self-service access to HR features. |

> [!WARNING]
> If a user only has `Customer` role and tries to access `/desk`, they will get a **500 Server Error**. This is normal — `Customer` is a portal-only role.

### Step 1: Create Groups in Keycloak

Groups in Keycloak must have the **exact same name** as Frappe Roles. Create groups for each role you want to assign.

1. Go to **Keycloak Admin** (`http://localhost:8686`).
2. Make sure you are in the **frappe-realm**.
3. Click **Groups** in the left sidebar.
4. Click **Create group**.
5. Create the following groups (one at a time):

| Group Name | Purpose |
|------------|---------|
| `Customer` | Portal access for customers |
| `Employee` | Desk access for employees |
| `System Manager` | Full admin access (use sparingly) |

> [!CAUTION]
> Group names are **case-sensitive**! `customer` ≠ `Customer`. The name must match the Frappe Role exactly.

### Step 2: Set Default Group (Auto-assign for New Users)

So that every new user who registers via Keycloak automatically gets a role:

1. Go to **Realm Settings** in the left sidebar.
2. Click the **User registration** tab.
3. Scroll down to the **Default groups** section.
4. Click **Add group**.
5. Select **Customer** (or whichever role you want as default).
6. Click **Add**.

Now, every new user who registers through Keycloak will automatically be added to the `Customer` group.

### Step 3: Assign Existing Users to Groups

For users who already exist in Keycloak:

1. Go to **Users** in the left sidebar.
2. Click on the user (e.g., **Ko Saw**).
3. Click the **Groups** tab.
4. Click **Join Group**.
5. Select the appropriate group(s):
   - `Customer` — for portal access only
   - `Customer` + `Employee` — for both portal and desk access
6. Click **Join**.

> [!TIP]
> A user can belong to **multiple groups**. For example, a user in both `Customer` and `Employee` groups will get both roles in Frappe.

### Step 4: Configure the Group Membership Mapper

This mapper tells Keycloak to include group names in the authentication token so Frappe can read them.

1. Go to **Clients** > **frappe-client**.
2. Click the **Client scopes** tab.
3. Click the link for **frappe-client-dedicated**.
4. If a mapper already exists (e.g., `groups`), click on it to edit. Otherwise, click **Add mapper** > **By configuration** > **Group Membership**.
5. Configure as follows:

| Field | Value |
|-------|-------|
| **Name** | `groups` |
| **Token Claim Name** | `roles` |
| **Full group path** | **OFF** ⚠️ |
| **Add to ID token** | **ON** |
| **Add to access token** | **ON** |
| **Add to userinfo** | **ON** |

6. Click **Save**.

> [!WARNING]
> **Full group path MUST be OFF!** If it is ON, Keycloak sends `/Customer` instead of `Customer`, which will NOT match the Frappe role name and the role assignment will silently fail.

### Step 5: Configure Frappe Social Login Key

Tell Frappe where to find the roles in the Keycloak token:

1. Log in to Frappe as **Administrator**.
2. Go to **Social Login Key** > **Keycloak**.
3. In the **User ID Property** field, set to `email`.
4. Click **Save**.

### Step 6: Set Default Role in Portal Settings (Fallback)

As an additional safety net, set a default role in Frappe for any user who signs up without specific roles:

1. Go to `http://localhost:8787/app/portal-settings`.
2. Set **Default Role** to `Customer`.
3. Click **Save**.

---

### Troubleshooting Role Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| User gets **500 Server Error** after login | User only has `Customer` role and tries to access `/desk` | Add `Employee` role (via Keycloak group or manually in Frappe) |
| User gets **403 Not Permitted** | User has no roles at all | Check Keycloak Default Groups and Group Membership mapper |
| User gets **"Not Permitted"** on OAuth callback | Server Script has a bug | Delete the Server Script, use Keycloak Groups instead |
| Roles from Keycloak not appearing in Frappe | `Full group path` is ON, or mapper Token Claim Name doesn't match | Set `Full group path` to OFF, verify Token Claim Name is `roles` |
| User sees only `/me` page (Settings) | User has portal-only role (Customer/Website User) | This is normal — add a desk-access role if needed |

---
---

## Part 5: Server Script for Keycloak Role Sync (Optional)

> [!NOTE]
> This section is **optional**. If you followed Part 4 (Keycloak Groups → Frappe Roles), you do NOT need Server Scripts. Only use this if you need custom logic beyond simple group-to-role mapping.

### 1. Enable Server Scripts Feature

Server Scripts are disabled by default in Frappe. You must enable them first.

**Option A: Enable for a specific site (recommended)**
```bash
# Inside Docker container
docker compose exec -T backend bench --site frontend set-config server_script_enabled 1

# Clear cache after enabling
docker compose exec -T backend bench --site frontend clear-cache
```

**Option B: Enable globally for all sites**
```bash
docker compose exec -T backend bench set-config -g server_script_enabled 1
docker compose exec -T backend bench --site frontend clear-cache
```

> [!IMPORTANT]
> After running the command, **restart the backend** and **refresh the browser** (`Ctrl + F5`) to make the yellow warning bar disappear:
> ```bash
> docker compose restart backend
> ```

### 2. Create the Server Script

1. Log in as **Administrator**.
2. Go to **Build** > **Server Script** (or search for "Server Script" in the search bar).
3. Click **+ Add Server Script**.
4. Fill in the fields:

| Field | Value |
|-------|-------|
| **Name** | `Keycloak Role Sync` |
| **Script Type** | `DocType Event` |
| **Reference Document Type** | `User` |
| **DocType Event** | `Before Save` |
| **Module (for export)** | *(Leave blank or select `Core`)* |

5. In the **Script** field, paste the following code:

```python
# Keycloak Role Sync - Before Save on User
# Uses 'doc' (NOT 'self') because Frappe Server Scripts
# run in a sandboxed environment where 'doc' is the document variable.

if doc.flags.get("social_login_data"):
    remote_roles = doc.flags.social_login_data.get("roles") or []

    added = False
    for role_name in remote_roles:
        doc.append("roles", {"role": role_name})
        added = True

    # If no roles from Keycloak, assign "Customer" as default
    if not added:
        doc.append("roles", {"role": "Customer"})
```

6. Click **Save**.

> [!WARNING]
> **Common Mistake**: Do NOT use `self` in Frappe Server Scripts. Always use `doc` to reference the current document. Using `self` will cause a **502 Bad Gateway** or **403 Not Permitted** error during login.

### 3. Alternative: Set Default Role Without Server Script

If you prefer not to use Server Scripts, you can set a default role using **Portal Settings**:

1. Go to `http://localhost:8787/app/portal-settings`
2. Set **Default Role** to `Customer`
3. Click **Save**

This will automatically assign the **Customer** role to all new users who sign up (including via Keycloak/Google).
