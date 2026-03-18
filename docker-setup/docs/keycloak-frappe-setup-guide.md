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
---

## Part 3: Advanced: Social Login with Google

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
