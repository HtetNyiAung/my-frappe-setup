# Digital Learning Platform — Administrator နှင့် Learner အသုံးပြုနည်း

**Platform:** Frappe LMS

**အသုံးပြုသူများ:** System Administrator, LMS Administrator, Instructor, Learner

**ရည်ရွယ်ချက်:** Internal/Private Digital Learning Portal ကို စီမံခြင်းနှင့် အသုံးပြုခြင်း

ဒီ Guide တွင် ရှင်းလင်းချက်ကို Myanmar ဘာသာဖြင့်ရေးထားပြီး Product အတွင်း
နှိပ်ရမည့် Menu, Button, Field, Role နှင့် Technical Term များကို English
အတိုင်းထားသည်။ UI Label များသည် Installed LMS Version/Localization အလိုက်
အနည်းငယ်ကွာနိုင်သည်။

## ဒီ Guide ကို သုံးနည်း

- **Part A** — Administrator/Instructor အတွက် Setup နှင့် Content Management
- **Part B** — Learner အတွက် Enrollment မှ Certificate ရယူသည်အထိ
- **Part C** — Security, Troubleshooting နှင့် Deployment Checklists

Screenshot ထည့်မည့်နေရာများကို `[Screenshot: ...]` ဖြင့် ဖော်ပြထားသည်။ Customer
ထံမပေးမီ Production UI မှ Personal Data/Secret မပါသော Screenshot ဖြင့်
အစားထိုးနိုင်သည်။

## အရေးကြီး Technical Terms

| Term | အဓိပ္ပာယ် |
|---|---|
| Course | သင်ယူရမည့် အကြောင်းအရာအစု |
| Chapter | Course အတွင်း အခန်းကြီး |
| Lesson | Chapter အတွင်း သင်ခန်းစာတစ်ခု |
| Program | Course များကို စုစည်းထားသော Learning Path |
| Batch | သတ်မှတ်ကာလ/အဖွဲ့အလိုက် Learner များစုထားခြင်း |
| Enrollment | Learner ကို Course/Batch တွင် စာရင်းသွင်းခြင်း |
| Quiz | အွန်လိုင်းမေးခွန်းစစ်ဆေးမှု |
| Assignment | တင်ပြရမည့် လုပ်ငန်းတာဝန် |
| Progress | Course ပြီးမြောက်မှုအခြေအနေ |
| Certificate | သတ်မှတ်ချက်ပြည့်မီပြီး Course ပြီးဆုံးကြောင်းအထောက်အထား |
| Role | User ၏ လုပ်ဆောင်ခွင့်အဆင့် |
| Permission | Data/Page/Action တစ်ခုကို အသုံးပြုခွင့် |

# Part A — Administrator Guide

## 1. ပထမဆုံး Admin Login နှင့် စစ်ဆေးချက်

1. Digital Learning URL ကို Browser တွင်ဖွင့်ပါ။
2. Named Administrator account ဖြင့် Login ဝင်ပါ။ Shared Administrator
   account ကို နေ့စဉ်မသုံးပါနှင့်။
3. Sidebar တွင် **Courses**, **Programs**, **Batches**, **Certifications**,
   **Quizzes**, **Assignments** စသည့် Required Menu များပေါ်ကြောင်းစစ်ပါ။
4. Platform name/logo, Language, Time Zone နှင့် Email Sender မှန်ကြောင်းစစ်ပါ။
5. Normal Learner Test account တစ်ခုဖြင့် Admin-only Menu/Data မမြင်ကြောင်း
   သီးခြားစမ်းပါ။

Internal App names ဖြစ်သော `frappe`, `lms`, `payments` ကို Rename/Delete
မလုပ်ပါနှင့်။ User မြင်သော Branding Label ကို Custom App/Settings မှသာပြောင်းပါ။

## 2. Branding နှင့် Localization

Branding ပြင်ရန် Frappe Desk တွင် **Website Settings**, **System Settings** နှင့်
LMS Settings ကို သုံးပါ။

| ပြင်ရန် | နမူနာ |
|---|---|
| Platform Name | Digital Learning |
| Logo | Approved organization logo |
| Primary Color | Approved brand color |
| Browser Title | Digital Learning |
| Email Sender Name | Digital Learning Support |

Learner-facing စာသားကို Myanmar သုံးနိုင်သော်လည်း Myanmar ပြန်ဆိုလျှင်
နားလည်ရခက်သော UI/Technical Term များကို English အတိုင်းထားပါ။ ဥပမာ
`Global Search`, `Course Editor`, `Publish`, `Unpublish`, `Enrollment`,
`Certificate`, `Quiz`, `Assignment`, `Progress`, `Role`, `Permission`။

Translation CSV တွင် English အတိုင်းထားလိုသော Label များကို Source/Target
တူအောင်ထားနိုင်သည်။ CSV Source string သည် Case, Space, Punctuation အားလုံး
UI Source နှင့် တိတိကျကျတူရမည်။

```csv
Unpublish,Unpublish
Publish,Publish
Global Search,Global Search
```

Translation/Asset ပြောင်းပြီးနောက် Cache ရှင်း၍ Browser Hard Refresh လုပ်ပါ။

```bash
./ops.sh clear-cache
```

```text
Ctrl + Shift + R
```

## 3. User နှင့် Role Management

### User အသစ်ထည့်ခြင်း

1. Desk **Global Search** မှ **User** ကိုဖွင့်ပါ။
2. **Add User** သို့မဟုတ် **New** နှိပ်ပါ။
3. Full Name နှင့် အသုံးပြုနိုင်သော Email ထည့်ပါ။
4. **Enabled** ဖွင့်ပါ။
5. လိုအပ်သော Role ကိုသာထည့်ပြီး **Save** လုပ်ပါ။
6. Approved channel မှ Login instruction ပို့ပါ။ Password ကို Documentation
   သို့မဟုတ် Group Chat ထဲ မပို့ပါနှင့်။

| User အမျိုးအစား | Role/Access အကြံပြုချက် |
|---|---|
| System Administrator | `System Manager` — Trusted technical admins only |
| LMS Administrator | LMS management Role — Course/User operations only |
| Instructor | Instructor/Course creation permissions |
| Learner | Portal/Learner Role only |

Role အမည်သည် Version အလိုက်ကွာနိုင်သည်။ `System Manager` ကို Login/Permission
error ပြင်ရန် Shortcut အဖြစ် မပေးပါနှင့်။ Menu ဖုံးထားခြင်းတစ်ခုတည်းမဟုတ်ဘဲ
Server-side Permission ကို User account အမှန်ဖြင့်စမ်းပါ။

### Learner ထံမှ Admin-only Menu ဖုံးခြင်း

- Learner တွင် Admin Role မရှိရပါ။
- **Statistics** ကဲ့သို့ Admin-only Page/Menu ကို Role condition ဖြင့်သာပြပါ။
- URL ကိုတိုက်ရိုက်ဝင်လျှင်လည်း Server က Access ပိတ်ကြောင်း စမ်းပါ။
- Guest/User role နှစ်မျိုးလုံးဖြင့် Authorized/Unauthorized Test လုပ်ပါ။

## 4. Course အသစ်ဖန်တီးခြင်း

### Course List သို့သွားခြင်း

1. Digital Learning Portal သို့ Admin/Instructor account ဖြင့် Login ဝင်ပါ။
2. Sidebar မှ **Courses** ကိုနှိပ်ပါ။
3. ညာဘက်အပေါ်ရှိ **Create** ကိုနှိပ်ပြီး **Course** ကိုရွေးပါ။ Version အချို့တွင်
   Button သည် **New Course** ဟုပေါ်နိုင်သည်။

```text
Digital Learning → Courses → Create → Course
```

### **New Course** Form ဖြည့်ခြင်း

| Field | ဖြည့်ရန် |
|---|---|
| **Title** | Course ခေါင်းစဉ်တိုတိုရှင်းရှင်း |
| **Category** | သက်ဆိုင်ရာ Course Category |
| **Instructors** | Course ကိုတာဝန်ယူမည့် Instructor |
| **Course Thumbnail** | Approved Image |
| **Short Introduction** | Course အကျဉ်းချုပ် |
| **Course Description** | ရည်ရွယ်ချက်၊ သင်ယူရမည့်အချက်များ၊ Audience |

Required Fields ဖြည့်ပြီး **Create** နှိပ်ပါ။ Draft အနေဖြင့်ဖန်တီးပြီး Content,
Permission နှင့် Learner View စစ်ပြီးမှ **Publish** လုပ်ပါ။

`[Screenshot: Courses page and Create button]`

`[Screenshot: New Course form with required fields]`

## 5. Course Editor တွင် Chapter နှင့် Lesson ထည့်ခြင်း

Course ဖန်တီးပြီးနောက်—

```text
Courses → Open Course → Course Editor
```

### Chapter ထည့်ခြင်း

1. **Course Editor** Tab ကိုနှိပ်ပါ။
2. **Create Chapter** သို့မဟုတ် **Add Chapter** ကိုနှိပ်ပါ။
3. **Title** ဖြည့်ပါ။ SCORM Package သုံးရန် Approved content ရှိမှ
   **SCORM Package** ကို Enable လုပ်ပါ။
4. **Create** နှိပ်ပါ။

Chapter အမည်ကို Learner နားလည်လွယ်သောအစဉ်ဖြင့်ပေးပါ။

```text
Chapter 1 — မိတ်ဆက်
Chapter 2 — အဓိကအကြောင်းအရာ
Chapter 3 — လက်တွေ့အသုံးချမှု
Chapter 4 — Assessment
```

### Lesson ထည့်ခြင်း

1. သက်ဆိုင်ရာ Chapter ကို Expand လုပ်ပါ။
2. **Add Lesson** ကိုနှိပ်ပါ။
3. Lesson Title ဖြည့်ပြီး Content type ကိုရွေးပါ။
4. Text, Video, PDF, Link သို့မဟုတ် Interactive content ထည့်ပါ။
5. Learner အား Preview ခွင့်ပြုလိုမှ **Include in Preview** ဖွင့်ပါ။
6. **Save** လုပ်ပြီး **Student View** ဖြင့်စစ်ပါ။

Lesson တစ်ခုတွင် ရည်ရွယ်ချက်တစ်ခုအဓိကထားပြီး အောက်ပါအစီအစဉ်သုံးနိုင်သည်။

1. Learning Objective
2. Main Content
3. Example/Reference
4. Summary
5. Quiz/Assignment သို့ ဆက်သွားရန် Instruction

`[Screenshot: Course Editor with Chapters and Add Lesson]`

## 6. PDF, Video နှင့် Attachments

### PDF

1. Lesson ကို Edit လုပ်ပါ။
2. Attachment/File upload control မှ PDF ရွေးပါ။
3. File name နှင့် Learner-facing Link text ရှင်းလင်းစွာပေးပါ။
4. Sensitive content ကို **Private** အဖြစ်ထားပါ။
5. **Save** ပြီး Learner Role ဖြင့် Open/Download စမ်းပါ။

### Video

1. Supported Video upload/URL/embed type ကိုရွေးပါ။
2. Approved source URL သို့မဟုတ် File ထည့်ပါ။
3. Caption/Description ထည့်ပါ။
4. Mobile Browser နှင့် Low-bandwidth connection တွင် စမ်းပါ။

Private URL ကို Browser မှရသော URL ဟုသာ ယုံ၍ပေးမထားပါနှင့်။ Parent Lesson,
Course Enrollment, Current User Permission နှင့် File privacy ကို Server-side
Validate လုပ်ရမည်။

## 7. Course Categories

Category သည် Course များကို ရှာဖွေရလွယ်အောင် ခွဲခြားပေးသည်။

1. LMS Admin area တွင် **Categories** ကိုဖွင့်ပါ။
2. **New** နှိပ်ပါ။
3. Category Name/Description ထည့်ပြီး **Save** လုပ်ပါ။
4. Course Form ရှိ **Category** Field တွင်ရွေးပါ။

Category များကို အလွန်အသေးစိတ်မခွဲဘဲ Organization ၏ Approved taxonomy ကို
သုံးပါ။ Duplicate/တူညီသောအမည် မဖန်တီးပါနှင့်။

## 8. Program နှင့် Batch

- **Program** — Course များကို Learning Path တစ်ခုအဖြစ် စုသည်။
- **Batch** — သတ်မှတ် Learner အဖွဲ့နှင့် Schedule ကို စီမံသည်။

### Program ဖန်တီးခြင်း

1. Sidebar **Programs → Create** ကိုနှိပ်ပါ။
2. Program Title/Description ဖြည့်ပါ။
3. Courses များကို လိုအပ်သောအစဉ်ဖြင့်ထည့်ပါ။
4. **Save** ပြီး Learner access စမ်းပါ။

### Batch ဖန်တီးခြင်း

1. Sidebar **Batches → Create** ကိုနှိပ်ပါ။
2. Batch Name, Course/Program, Start/End Date နှင့် Instructor ဖြည့်ပါ။
3. Learners/Members ထည့်ပါ။
4. Schedule/Capacity/Visibility settings စစ်ပြီး **Save** လုပ်ပါ။

## 9. Enrollment

### Learner တစ်ယောက်ကို Course ထဲထည့်ခြင်း

1. သက်ဆိုင်ရာ Course ကိုဖွင့်ပါ။
2. **Enrollments** သို့မဟုတ် **Members** ကိုဖွင့်ပါ။
3. **Add Member/Enroll Student** ကိုနှိပ်ပါ။
4. User ကိုရွေးပြီး **Save/Enroll** လုပ်ပါ။
5. Learner account ဖြင့် **My Courses** တွင်ပေါ်ကြောင်းစစ်ပါ။

### Batch ဖြင့် Learners အစုလိုက်ထည့်ခြင်း

1. Batch ကိုဖွင့်ပါ။
2. **Members** တွင် Users ထည့်ပါ။
3. Batch ချိတ်ထားသော Course/Program မှန်ကြောင်းစစ်ပါ။
4. Notification ပို့မည်ဆိုပါက Outgoing Email အလုပ်လုပ်ကြောင်းအရင်စမ်းပါ။

Duplicate Enrollment, Disabled User နှင့် Wrong Course/Batch ကို မသိမ်းမီ
စစ်ပါ။ Enrollment ဖယ်ရှားခြင်းက Learner Progress/Certificate ပေါ် သက်ရောက်နိုင်၍
အတည်ပြုချက်နှင့် Audit trail ထားပါ။

## 10. Quiz နှင့် Assessment

1. Sidebar **Quizzes → Create** ကိုဖွင့်ပါ။
2. Quiz Title, Instructions, Passing Score နှင့် Attempts သတ်မှတ်ပါ။
3. Questions/Answers ထည့်ပြီး Correct Answer သတ်မှတ်ပါ။
4. Quiz ကို သက်ဆိုင်ရာ Lesson/Course နှင့် ချိတ်ပါ။
5. **Save** ပြီး Learner account ဖြင့် Attempt/Result စမ်းပါ။

မေးခွန်းအမျိုးအစားသည် Version အလိုက် Multiple Choice, Multiple Select,
True/False စသည်ဖြင့်ကွာနိုင်သည်။ Ambiguous မေးခွန်းမရေးဘဲ Correct Answer,
Passing Score, Retake policy နှင့် Feedback ကို Publish မလုပ်မီ Review လုပ်ပါ။

## 11. Assignment

1. **Assignments → Create** ကိုဖွင့်ပါ။
2. Title, Instructions, Due Date နှင့် Submission requirement ဖြည့်ပါ။
3. Course/Lesson နှင့် ချိတ်ပါ။
4. Learner submission ကို Instructor account ဖြင့် Review/Grade လုပ်ပါ။
5. Learner က Result/Feedback မြင်ကြောင်းစစ်ပါ။

Submission files တွင် Personal/Sensitive Data ပါနိုင်သောကြောင့် Private Access
နှင့် Retention policy ကို သတ်မှတ်ပါ။

## 12. Certificate Configuration

Certificate ထုတ်ပေးမည့် Course တွင် **Certification** သို့မဟုတ် Certificate
setting ကို Enable လုပ်ပါ။ Version ပေါ်မူတည်၍ Certificate Template/Print Format,
Completion Percentage, Passing Quiz Score စသည့် Conditions ရှိနိုင်သည်။

1. Course အတွက် Completion requirements သတ်မှတ်ပါ။
2. Certificate Template, Title, Logo, Signatory, Date format စစ်ပါ။
3. Test Learner ဖြင့် Lessons/Quiz အားလုံးပြီးအောင်လုပ်ပါ။
4. Certificate Generate/Download အောင်မြင်ကြောင်းစစ်ပါ။
5. Learner Name, Course Name, Completion Date နှင့် Certificate ID မှန်ကြောင်း
   Review လုပ်ပါ။

Certificate ကို Manual ထုတ်ပေးခြင်းမပြုမီ Course Completion နှင့် Assessment
Result ကို အတည်ပြုပါ။ Revoke/Reissue process ကိုလည်း Admin team သတ်မှတ်ထားပါ။

## 13. Notifications နှင့် Email

Notification မဖွင့်မီ Outgoing Email ကို **Send Test Email** ဖြင့်စမ်းပါ။

အသုံးများသော Notifications—

- Enrollment Confirmation
- Course/Batch Start Reminder
- Assignment Due Reminder
- Course Completion
- Certificate Available

User Email မှန်ကြောင်း၊ Duplicate Notification မပို့ကြောင်းနှင့် Email content
ထဲ Sensitive Data မပါကြောင်းစစ်ပါ။

## 14. Progress Tracking နှင့် Statistics

Admin/Instructor သည် Course/Batch ရှိ **Progress**, **Enrollments** သို့မဟုတ်
**Statistics** မှ—

- Enrollment count
- Lesson completion
- Quiz attempts/scores
- Course completion
- Certificate status

တို့ကို စစ်နိုင်သည်။ Statistics သည် Admin/Authorized Staff အတွက်သာဖြစ်ပါက
Learner Sidebar တွင် ဖုံးထားပြီး URL တိုက်ရိုက်ဝင်သည့်အခါ Permission ပိတ်ကြောင်း
စမ်းပါ။ Aggregate counts သည် Permission ဖြင့်ခွင့်ပြုထားသော Data မှသာ တွက်ရမည်။

## 15. Reports နှင့် Data Protection

Report/Export ကို လိုအပ်သော Columns/Rows သာထုတ်ပါ။ User Email, Quiz Result,
Progress နှင့် Certificate Data ကို Personal Data အဖြစ် ကာကွယ်ပါ။ Export file
ကို Approved Storage တွင်သာသိမ်းပြီး Retention ပြည့်လျှင် ဖျက်ပါ။

Report numbers ကို Decision အတွက်သုံးမည်ဆိုပါက Filter, Date Range, Timezone,
Course/Batch scope နှင့် Last Updated time ကို အတည်ပြုပါ။

## 16. Guest Access နှင့် Private Portal

Internal Portal အတွက် **Allow Guest Access** ကို Default Off ထားရန် အကြံပြုသည်။

```text
LMS Settings → Settings → System Configurations → Allow Guest Access = Off
```

Setting ပြောင်းပြီး Guest Browser/Incognito Window ဖြင့် Course/Batch list နှင့်
Private files မမြင်ကြောင်းစစ်ပါ။ UI toggle ပိတ်ရုံမဟုတ်ဘဲ Server-side Permission
နှင့် File access ကိုပါ စမ်းရမည်။ Public Course လိုအပ်ပါက Approved Content ကိုသာ
သီးခြား Publish လုပ်ပါ။

## 17. Sidebar နှင့် Menu Customization

- Learner အတွက် လိုအပ်သော Menu သာပြပါ။
- Admin-only **Statistics**, Settings/User Management ကို Role-aware condition
  ဖြင့်ဖုံးပါ။
- Visible Label ပြောင်းရာတွင် Translation/Custom App သုံးပြီး Internal Route,
  DocType name, Fieldname မပြောင်းပါနှင့်။
- Core Frappe/LMS source ကိုတိုက်ရိုက်မပြင်ပါနှင့်။ Upgrade-safe Custom App
  implementation ကိုသုံးပါ။

# Part B — Learner Guide

## 18. Login ဝင်ခြင်း

1. Digital Learning URL ကို Browser တွင်ဖွင့်ပါ။
2. Email/Username နှင့် Password ထည့်ပါ၊ သို့မဟုတ် Organization ပေးထားသော SSO
   Button ကိုနှိပ်ပါ။
3. **Login** နှိပ်ပါ။
4. Password မေ့ပါက **Forgot Password** သုံးပါ။ Reset Email မရပါက Spam folder
   စစ်ပြီး Support ကိုဆက်သွယ်ပါ။ Password မျှဝေခြင်းမလုပ်ပါနှင့်။

## 19. Course ရှာခြင်း

- Sidebar **Courses** မှ ရရှိနိုင်သော Courses ကိုကြည့်ပါ။
- **Search** ဖြင့် Course Title/Keyword ရှာပါ။
- **Category** သို့မဟုတ် တခြား Filters ဖြင့် စစ်ပါ။
- Enrollment ပြီး Course များကို **My Courses** သို့မဟုတ် Home dashboard မှ
  ဖွင့်ပါ။

Course မမြင်ပါက Login account မှန်ခြင်း၊ Enrollment/Batch Date နှင့် Course
Published status ကို Admin ထံစစ်ခိုင်းပါ။

## 20. Course ကို Enrollment လုပ်ခြင်း

Self-enrollment ခွင့်ပြုထားသော Course—

1. Course Card/Title ကိုနှိပ်ပါ။
2. Description, Instructor, Chapters နှင့် Requirements ကိုဖတ်ပါ။
3. **Enroll**, **Start Learning** သို့မဟုတ် Version တွင်ပေါ်သော Equivalent
   Button ကိုနှိပ်ပါ။
4. Confirmation ပြီး **Start/Continue** ကိုနှိပ်ပါ။

Admin-controlled Course တွင် Enrollment Button မပေါ်နိုင်ပါ။ Admin က Course
သို့မဟုတ် Batch တွင်ထည့်ပေးပြီးမှ **My Courses** တွင်ပေါ်မည်။

## 21. Lesson သင်ယူခြင်း

1. **My Courses → Course** ကိုဖွင့်ပါ။
2. Chapter ကိုရွေး၍ ပထမ Lesson ကိုဖွင့်ပါ။
3. Text ဖတ်ခြင်း၊ Video ကြည့်ခြင်း၊ PDF/Attachment ဖွင့်ခြင်းတို့ကို ပြီးစီးပါ။
4. **Mark Complete**, **Next** သို့မဟုတ် System ၏ Auto-completion ကိုသုံးပါ။
5. Sidebar Progress ပြောင်းကြောင်းစစ်ပါ။

Video/PDF မဖွင့်ပါက Browser Refresh လုပ်ပြီး Network စစ်ပါ။ Private File URL ကို
အခြားသူထံ မမျှဝေပါနှင့်။

## 22. Quiz ဖြေခြင်း

1. Course/Lesson ရှိ Quiz ကိုဖွင့်ပါ။
2. Instructions, Time Limit, Passing Score နှင့် Attempts ကိုဖတ်ပါ။
3. Answers ရွေးပြီး မတင်မီ Review လုပ်ပါ။
4. **Submit** နှိပ်ပြီး Result/Feedback ကိုကြည့်ပါ။
5. မအောင်မြင်ပါက Retake ခွင့်ရှိသရွေ့ ပြန်လေ့လာပြီး ထပ်ဖြေပါ။

Quiz window ကို Submit မလုပ်မီ ပိတ်ခြင်း၊ Browser Back/Refresh လုပ်ခြင်းကို
ရှောင်ပါ။ Technical error ဖြစ်ပါက Screenshot တွင် Personal Data မပါအောင်
ဖုံးကွယ်ပြီး Course/Quiz name နှင့် ဖြစ်ပွားချိန်ကို Support ထံပို့ပါ။

## 23. Assignment တင်ခြင်း

1. Assignment ကိုဖွင့်ပြီး Instructions/Due Date ကိုဖတ်ပါ။
2. Allowed file type/size နှင့် Filename rule ကိုလိုက်နာပါ။
3. Answer/File ကို Upload လုပ်၍ **Submit** နှိပ်ပါ။
4. Submission status မှန်ကြောင်းစစ်ပါ။
5. Instructor Feedback/Grade ရလာပါက ပြန်ကြည့်ပါ။

## 24. Progress ကြည့်ခြင်း

Course page သို့မဟုတ် **My Courses** တွင် Completion Percentage ကိုကြည့်ပါ။
Progress မတိုးပါက—

- Required Lesson အားလုံး Complete ဖြစ်/မဖြစ်
- Video/Content Completion condition
- Required Quiz/Assignment Submit/Pass ဖြစ်/မဖြစ်
- Browser/Network error ရှိ/မရှိ

စစ်ပါ။ ပြဿနာဆက်ရှိပါက Course Title, Lesson Title နှင့် ဖြစ်ပွားချိန်ကို Admin
ထံပို့ပါ။

## 25. Certificate ရယူခြင်း

1. Required Lessons အားလုံး Complete လုပ်ပါ။
2. Required Quiz/Assignment နှင့် Passing Score ပြည့်ပါစေ။
3. Course Progress `100%` သို့မဟုတ် သတ်မှတ် Completion condition ပြည့်ကြောင်း
   စစ်ပါ။
4. Course page ရှိ **Certificate**, **Get Certificate** သို့မဟုတ်
   **Download Certificate** ကိုနှိပ်ပါ။
5. PDF ဖွင့်ပြီး Name, Course, Date နှင့် Certificate ID မှန်ကြောင်းစစ်ပါ။
6. Approved Device/Storage တွင်သိမ်းပါ။

Button မပေါ်ပါက Missing Lesson/Quiz, Certificate-enabled Course ဖြစ်/မဖြစ်နှင့်
Enrollment status ကို Admin ထံစစ်ခိုင်းပါ။ Certificate ကို ကိုယ်တိုင်ပြင်ဆင်ခြင်း
သို့မဟုတ် တခြားသူ၏ Certificate သုံးခြင်းမပြုပါနှင့်။

# Part C — Operations, Security နှင့် Support

## 26. Backup နှင့် Maintenance

Administrator သည် အနည်းဆုံး Database, Public files, Private files, Site
Configuration, `encryption_key` နှင့် S3/MinIO objects ကို Backup လုပ်ရမည်။

- Daily Automated Backup
- Update မတိုင်မီ Manual Verified Backup
- Server ပြင်ပ Offsite Copy
- Periodic Non-production Restore Test

အသေးစိတ်ကို [Backup Automation လမ်းညွှန်](../operations/backup-automation-guide.md)
နှင့် [Restore လမ်းညွှန်](../operations/restore.md) တွင်ဖတ်ပါ။

## 27. Troubleshooting

### Login မဝင်နိုင်ခြင်း

- Email/Username, Password နှင့် User **Enabled** status စစ်ပါ။
- SSO သုံးပါက IdP status, Redirect URL နှင့် User assignment စစ်ပါ။
- **Forgot Password** စမ်းပြီး Email Queue/Spam စစ်ပါ။

### Course မမြင်ခြင်း

- Course **Published** ဖြစ်ကြောင်းစစ်ပါ။
- Enrollment/Batch Membership နှင့် Start/End Date စစ်ပါ။
- Learner Role/Permission ကို Admin account မဟုတ်သော Test User ဖြင့်စမ်းပါ။

### Translation/Branding အဟောင်းပေါ်ခြင်း

```bash
./ops.sh clear-cache
```

ပြီးလျှင် `Ctrl + Shift + R` Hard Refresh လုပ်ပါ။ Translation Source string
Case/Punctuation တိကျမှုနှင့် Custom App install/migrate status စစ်ပါ။

### PDF/Video မပေါ်ခြင်း

- File record, Privacy, Parent Course/Lesson Permission စစ်ပါ။
- S3/MinIO Enable ဖြစ်ပါက Endpoint/Bucket/Object နှင့် App Server connectivity
  စစ်ပါ။
- Upload size limit နှင့် Browser Network error စစ်ပါ။

### Quiz Result/Progress မပြောင်းခြင်း

- Submission status, Required Lesson နှင့် Passing Score စစ်ပါ။
- Worker/Scheduler status နှင့် Logs စစ်ပါ။

```bash
./ops.sh status
./ops.sh logs backend
./ops.sh logs queue-short
./ops.sh logs scheduler
```

## Production Handover Checklist

### Administrator

- [ ] Platform Branding, Language, Time Zone နှင့် Email မှန်သည်။
- [ ] Guest Access Off ဖြစ်ပြီး Public Content ကိုသာ Intentional Publish လုပ်ထားသည်။
- [ ] Admin/Instructor/Learner Roles နှင့် Server-side Permissions စမ်းထားသည်။
- [ ] Course → Chapter → Lesson → Quiz/Assignment → Certificate workflow စမ်းထားသည်။
- [ ] Learner Sidebar တွင် Admin-only Statistics/Settings မပေါ်ပါ။
- [ ] Private Files နှင့် S3/Local Storage access စမ်းထားသည်။
- [ ] Backup, Offsite Copy နှင့် Restore Test အောင်မြင်သည်။

### Learner

- [ ] Login/Password Reset အလုပ်လုပ်သည်။
- [ ] Search/Filter, Enrollment နှင့် **My Courses** အလုပ်လုပ်သည်။
- [ ] Lesson, Video, PDF နှင့် Quiz/Assignment အလုပ်လုပ်သည်။
- [ ] Progress မှန်ပြီး Certificate Download ရသည်။
- [ ] Mobile Browser နှင့် Supported Desktop Browser စမ်းထားသည်။

### Customer Handover

- [ ] Screenshots တွင် Test Personal Data/Secrets မပါပါ။
- [ ] URL, Support Contact နှင့် Escalation Process အမှန်ထည့်ထားသည်။
- [ ] Named Administrator နှင့် Emergency Admin accounts သီးခြားရှိသည်။
- [ ] Known Issues, Maintenance Window နှင့် Backup Responsibility မှတ်တမ်းရှိသည်။
- [ ] Guide ကို လက်ရှိ Production Version/UI နှင့် နောက်ဆုံးပြန်စစ်ထားသည်။

## နောက်ဆုံးမှတ်ချက်

Course/Role/Permission/Storage ပြင်ဆင်မှုကို Production တိုက်ရိုက်မလုပ်မီ Test
User နှင့် Staging/Approved Pilot တွင် စမ်းပါ။ Visible Menu ဖုံးထားခြင်းကို
Security ဟုမယူဆဘဲ Server-side Permission နှင့် Private File Access ကို
အမြဲတမ်း သီးခြားအတည်ပြုပါ။
