# changAI Setup Guide

## 🤖 AI Chat Integration Setup

This guide covers the complete setup and configuration of **changAI** - AI-powered chat interface for ERPNext.

---

## 📋 Prerequisites

- ✅ **Frappe v16** setup completed
- ✅ **changAI app** installed via apps.json
- ✅ **Google Cloud Project** created
- ✅ **Vertex AI API** enabled

---

## 🔧 Configuration Steps

### Step 1: Get Google Cloud Credentials

#### A. Get Gemini API Key (Free Tier)
1. Go to: https://aistudio.google.com/app/apikey
2. Sign in with Google account
3. Click **"Create API Key"**
4. Copy the generated key (starts with `AIza...`)

#### B. Get Project ID
1. In the same API page, find your **Project ID/Number**
2. Note the project number (e.g., `371884246679`)

#### C. Enable Vertex AI API
1. Go to: https://console.developers.google.com/apis/api/aiplatform.googleapis.com/overview?project=YOUR_PROJECT_ID
2. Click **"Enable"**
3. Wait 2-5 minutes for activation

### Step 2: Configure changAI Settings

#### Access Settings
1. Login to ERPNext: `http://localhost:8000`
2. Search for **"changAI Settings"**
3. Open the settings page

#### Authentication Configuration

**Option A: Free Tier (Recommended)**
```
✅ Gemini API Key: Your API key from AI Studio
✅ Gemini Project ID: Your project number (e.g., 371884246679)
✅ Gemini_location: us-central1 (or us-east1)
❌ Service Account Credential: Leave empty
```

**Option B: Service Account (Advanced)**
```
✅ Gemini API Key: Your API key
✅ Gemini Project ID: Your project number
✅ Gemini_location: us-central1
✅ Service Account Credential: JSON content from service account
```

### Step 3: Model Setup

#### Download Embedding Model
1. In changAI Settings, click **"Download Embedding Model"**
2. Wait for download to complete (2-5 minutes)
3. Verify success message

#### Update Master Data
1. Go to **"Training"** tab
2. Click **"Update Master Data"**
3. Wait for sync to complete

---

## 🎯 Training Setup Guide (Step-by-Step)

This section shows how to properly train changAI with your ERPNext data for best performance.

### 📋 Training Configuration Steps

#### Step 1: Access Training Tab
1. In ERPNext, search for **"changAI Settings"**
2. Click the **"Training"** tab
3. You'll see the training configuration interface

#### Step 2: Set Record Size
```
Field: "Choose a record size between 1000 to 1500"
Recommended: 1000 (for initial setup)
Action: Enter "1000" in the field
```

#### Step 3: Create Training Data
```
Button: "Create training data"
Action: Click this button
Wait: 1-2 minutes for completion
Result: Base training data is generated
```

#### Step 4: Configure Training Modules
```
Table: "Module and Description"
Default modules: HR, CRM
Recommended additions:
- Sales - အရောင်းအဝယ်စနစ်
- Stock - စတောင်းစုံး
- Accounts - ငွေရေးကြေးရေး
- Projects - စီမံကိန်းများ

Action: Click "Add row" to add more modules
```

#### Step 5: Update Master Data File
```
Button: "Update MasterData file"
Purpose: Sync ERPNext master data with AI
Action: Click this button
Wait: 2-5 minutes for completion
Result: Customer, Item, Supplier data indexed
```

#### Step 6: Update Schema File
```
Button: "Update Schema file"
Purpose: Update database schema understanding
Action: Click this button
Wait: 1-3 minutes for completion
Result: AI understands your custom fields and doctypes
```

#### Step 7: Save Settings
```
Button: "Save" (top right)
Action: Click to save all training configurations
```

### 🎯 Complete Training Workflow

```
1. Set Record Size → 1000
2. Create Training Data → Wait 1-2 min
3. Add Modules → HR, CRM, Sales, Stock, Accounts
4. Update MasterData → Wait 2-5 min
5. Update Schema → Wait 1-3 min
6. Save Settings
7. Test with queries
```

### ✅ Verification Steps

After training completion, test with these queries:

```
"How many customers are there?" → Should show customer count
"What are our top selling items?" → Should show items
"Show me pending sales orders" → Should show orders
"Employee count by department" → Should show HR data
```

### 🔄 Maintenance Schedule

**Weekly Tasks:**
- Update Master Data (if new records added)
- Check training accuracy

**Monthly Tasks:**
- Update Schema (if custom fields added)
- Create new training data
- Review module list

### ⚠️ Common Training Issues

#### Training Data Creation Failed
```
❌ Problem: "Create training data" fails
✅ Solution:
   1. Check API credentials
   2. Verify internet connection
   3. Try again after 1 minute
```

#### Master Data Update Failed
```
❌ Problem: "Update MasterData file" fails
✅ Solution:
   1. Check database connection
   2. Verify permissions
   3. Ensure modules are installed
```

#### Schema Update Failed
```
❌ Problem: "Update Schema file" fails
✅ Solution:
   1. Check custom doctypes
   2. Verify field permissions
   3. Restart backend if needed
```

### 🎯 Best Practices

#### For Best Results:
1. **Start with small record size** (1000)
2. **Add modules gradually** (HR → CRM → Sales)
3. **Test after each step**
4. **Monitor training time** (should be < 5 minutes each)
5. **Keep training data updated** (monthly)

#### Performance Tips:
- Use **Local Mode** for better privacy
- **Limit concurrent queries** during training
- **Schedule training** during off-peak hours
- **Monitor API usage** with Google Cloud

---

## 🚀 Usage

### Basic Queries
```
"Customer တွေ ဘယ်လောက်ရှိလဲ?"  # ဖောင်းစုံစမ်း
"ဒီလ အရောင်းရေးဝင်ငွေ ဘယ်လောက်ရှိလဲ?"  # ဒီလ ရောင်းရေး
"Item တွေ စုစုံး ဘယ်လောက်ရှိလဲ?"  # စတောင်းစုံး
"Employee တွေ စုစုံး ဘယ်လောက်ရှိလဲ?"  # ဝန်ထမ်း
```

### Advanced Features
- **Multi-language Support**: Configure in changAI Settings
- **Voice Assistant**: Enable in Voice Settings tab
- **Debug Mode**: Check generated SQL and processing steps
- **Custom Training**: Module-specific training data

---

## 🔧 Troubleshooting

### Common Issues

#### 403 PERMISSION_DENIED Error
```
❌ Cause: Vertex AI API not enabled or service account issues
✅ Solution: 
   1. Enable Vertex AI API
   2. Wait 5-10 minutes
   3. Use correct Project ID
   4. Try API Key only (Free Tier)
```

#### Service Account Credentials Missing
```
❌ Error: "Service Account Credentials are missing"
✅ Solution:
   1. Create service account in Google Cloud
   2. Grant "Vertex AI User" role
   3. Generate JSON key
   4. Copy entire JSON content to changAI Settings
```

#### Model Download Failed
```
❌ Cause: Network issues or insufficient permissions
✅ Solution:
   1. Check internet connection
   2. Verify API credentials
   3. Retry download
```

### Location Issues
```
❌ Error: "User location is not supported"
✅ Solution:
   1. Set Gemini_location to us-central1
   2. Try us-east1
   3. Use VPN if needed
```

---

## 🎯 Best Practices

### Performance Optimization
- Use **Free Tier** for development/testing
- Cache frequently accessed data
- Limit concurrent queries

### Security
- Never share API keys publicly
- Use service accounts for production
- Regularly rotate credentials

### Data Privacy
- **Local Mode**: Keeps data on your server
- **Permission Aware**: Respects Frappe permissions
- **Master Data Sync**: Updates with latest ERPNext data

---

## 📚 Additional Resources

### Documentation
- [changAI GitHub](https://github.com/ERPGulf/changAI)
- [Google AI Studio](https://aistudio.google.com/)
- [Vertex AI Documentation](https://cloud.google.com/vertex-ai)

### Community Support
- [Frappe Forum](https://discuss.frappe.io/)
- [changAI Issues](https://github.com/ERPGulf/changAI/issues)

---

## 🔄 Updates and Maintenance

### Regular Tasks
- **Weekly**: Update Master Data
- **Monthly**: Download updated embedding models
- **Quarterly**: Review API usage and costs

### Backup Configuration
- Export changAI settings regularly
- Document custom configurations
- Test after major updates

---

*Last Updated: April 2026*
