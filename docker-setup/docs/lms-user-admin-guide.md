# Hluttaw Digital Learning Platform - User and Administration Guide

Pilot and R&D Phase

Platform: Frappe LMS  
Deployment Type: Standalone LMS, no ERPNext  
Audience: Super Admin, Training Admin, MPs, Parliamentary Staff, Committee Members  
Access Model: Internal/private learning portal

## Document Purpose

This guide explains how to use and administer the Hluttaw Digital Learning Platform during the pilot and R&D phase. It is written for beginners and operational teams who need clear steps, safe configuration guidance, and practical workflows.

The platform is intended for internal parliamentary learning, including courses for MPs, parliamentary staff, committees, and training administrators.

## Important Terms

| Term | Meaning |
|---|---|
| LMS | Learning Management System |
| Course | A structured learning program made of lessons, files, videos, and quizzes |
| Lesson | One learning unit inside a course |
| Batch | A learning session or group of learners assigned to a course |
| Student | A learner, such as an MP, staff member, or committee member |
| Training Admin | User who creates and manages learning content |
| Super Admin | User with full system administration rights |
| Workspace | A Desk menu area used by administrators |
| Desktop Icon | A clickable tile on the Frappe desktop screen |

## Table of Contents

1. Initial LMS Setup
2. Branding and Localization
3. User and Role Management
4. Creating Courses
5. Creating Lessons
6. Uploading PDFs and Videos
7. Course Categories
8. Batches and Learning Sessions
9. Student Enrollment
10. Assessments and Quizzes
11. Certificates
12. Notifications
13. Progress Tracking
14. Reports and Analytics
15. Internal Resource Management
16. Committee-Based Access
17. Private and Internal Access
18. Sidebar and Menu Customization
19. Myanmar Language Support
20. Microsoft Login and SSO Overview
21. Backup Recommendations
22. Best Practices
23. Pilot Deployment Workflow
24. User Guide
25. Security and Permissions Guide
26. Troubleshooting Guide
27. Deployment Checklist

---

# 1. Initial LMS Setup

## Purpose

Initial setup prepares the LMS for parliamentary training use. It includes site configuration, basic branding, administrator accounts, learning categories, and access control.

## Recommended Pilot Setup

| Setting | Recommendation |
|---|---|
| Site name | Use the official internal training domain |
| Access type | Internal/private only |
| Admin account | Use named admin accounts, not shared admin accounts |
| Demo content | Keep only if useful for training; remove before production |
| Public course access | Disabled unless approved |
| User registration | Admin-controlled during pilot |
| Language | English plus Myanmar content where needed |

## First Login

1. Open the LMS URL.
2. Log in as Administrator or Super Admin.
3. Confirm the platform title shows the institution name.
4. Confirm LMS menu is visible.
5. Confirm only required apps are installed: Frappe, Payments, LMS.

[Screenshot: Login page with institutional branding]

[Screenshot: LMS home page after administrator login]

## Initial Admin Checks

Navigation:

`Desk > Search > Installed Applications`

Check that the system is standalone LMS only. ERPNext should not be required for this setup.

Navigation:

`Desk > User > Administrator`

Check that the Administrator password has been changed from the default.

## What Admins Should Avoid Changing

Do not rename or delete these internal application names:

| Internal Name | Reason |
|---|---|
| frappe | Core framework required by the platform |
| lms | Main LMS application |
| payments | Required dependency for LMS |

Visible labels can be changed. Internal app names should not be changed.

---

# 2. Branding and Localization

## Purpose

Branding makes the LMS look like an official parliamentary learning portal. Localization helps users understand content in English and Myanmar.

## Branding Areas

| Area | Example |
|---|---|
| Platform name | Hluttaw Digital Learning Platform |
| Logo | Parliament or official training logo |
| Primary color | Institutional color |
| Browser title | Hluttaw Digital Learning Platform |
| LMS sidebar title | Hluttaw Digital Learning Platform |
| Desktop icon label | Hluttaw Digital Learning Platform |

## Change Website and App Name

Navigation:

`Desk > Search > Website Settings`

Recommended fields:

| Field | Recommended Value |
|---|---|
| App Name | Hluttaw Digital Learning Platform |
| Brand HTML | Hluttaw Digital Learning Platform |
| Title Prefix | Hluttaw Digital Learning Platform |

[Screenshot: Website Settings branding fields]

## Change System App Name

Navigation:

`Desk > Search > System Settings`

Set the app name if the field is available.

[Screenshot: System Settings app name]

## Change LMS Desktop Tile Name

The tile shown on the Frappe desktop may come from a Desktop Icon record.

Navigation:

`Desk > Search > Desktop Icon`

Open:

`Frappe Learning`

Change visible label to:

`Hluttaw Digital Learning Platform`

Do not change the internal name unless you fully understand upgrade impact.

[Screenshot: Desktop Icon label field]

## Localization Guidance

Use English for system administration and Myanmar for learner-facing content where required.

Recommended approach:

| Content Type | Recommended Language |
|---|---|
| Admin configuration | English |
| Course title | English, Myanmar, or bilingual |
| Lesson text | Myanmar where needed |
| Legal/parliamentary terms | Use approved official terminology |
| Certificates | Use official language standard |

---

# 3. User and Role Management

## Purpose

User and role management controls who can access the platform, create courses, manage students, and view reports.

## Recommended User Groups

| User Group | Description |
|---|---|
| Super Admin | Full platform administrator |
| Training Admin | Creates courses, lessons, quizzes, batches, enrollments |
| MP | Learner role for Members of Parliament |
| Parliamentary Staff | Learner role for internal staff |
| Committee Member | Learner role for committee-specific courses |

## Add a New User

Navigation:

`Desk > Search > User > New`

Steps:

1. Enter full name.
2. Enter official email address.
3. Enable the user.
4. Assign roles based on responsibility.
5. Save.
6. Send login instructions through the approved internal communication channel.

[Screenshot: New User form]

## Recommended Role Assignment

| User Type | Recommended Roles |
|---|---|
| Super Admin | System Manager, LMS Manager or equivalent LMS admin role |
| Training Admin | LMS Manager, Instructor, Course Creator where available |
| MP | Learner/Student role |
| Parliamentary Staff | Learner/Student role |
| Committee Member | Learner/Student role plus committee group membership |

Role names may vary slightly depending on installed LMS version. Use the closest LMS-specific role available.

## Security Warning

Avoid giving System Manager access to normal training users. System Manager should be limited to trusted technical administrators.

---

# 4. Creating Courses

## Purpose

Courses organize learning content into a structured program. A course can include lessons, files, videos, quizzes, assignments, and certificates.

## Add a Course

Navigation:

`LMS > Courses > New Course`

Steps:

1. Click Courses.
2. Click New Course.
3. Enter the course title.
4. Enter a short introduction.
5. Select a category.
6. Add a cover image if available.
7. Add course description.
8. Save as draft.
9. Add lessons and quizzes.
10. Review the course.
11. Publish only after approval.

[Screenshot: New Course button]

[Screenshot: Course creation form]

## Recommended Course Fields

| Field | Recommended Use |
|---|---|
| Title | Clear training title |
| Short Introduction | One or two sentence summary |
| Description | Full course purpose and target audience |
| Category | Parliamentary function or subject area |
| Published | Enable only after review |
| Paid Course | Usually disabled for internal training |

## Parliamentary Course Examples

| Course Title | Audience |
|---|---|
| Introduction to Parliamentary Procedure | MPs, Staff |
| Committee Reporting and Documentation | Committee Members |
| Ethics and Code of Conduct | MPs, Staff |
| Legislative Research Basics | Staff, Committee Members |
| Digital Tools for Parliamentary Work | MPs, Staff |

## What to Avoid

Do not publish incomplete courses.  
Do not use unclear course titles.  
Do not upload confidential documents to public courses.  
Do not create duplicate courses without a naming standard.

---

# 5. Creating Lessons

## Purpose

Lessons are the learning units inside a course. A good lesson should be short, focused, and easy to complete.

## Add a Lesson

Navigation:

`LMS > Courses > Open Course > Add Chapter > Add Lesson`

Steps:

1. Open the course.
2. Add a chapter if needed.
3. Click Add Lesson.
4. Enter lesson title.
5. Add lesson content.
6. Attach files or videos where needed.
7. Save.
8. Preview as learner.

[Screenshot: Add Chapter button]

[Screenshot: Add Lesson editor]

## Recommended Lesson Structure

| Section | Description |
|---|---|
| Objective | What the learner will understand |
| Main content | Reading, video, or document |
| Key points | Short summary |
| Activity | Optional task or discussion |
| Quiz | Optional assessment |

## Lesson Length Recommendation

For MPs and parliamentary staff, keep lessons short:

| Content Type | Recommended Length |
|---|---|
| Text lesson | 5-10 minutes |
| Video lesson | 3-8 minutes |
| PDF reading | 3-10 pages for normal lessons |
| Quiz | 5-10 questions |

---

# 6. Uploading PDFs and Videos

## Purpose

PDFs and videos allow administrators to share training material, procedural guides, policy references, and recorded sessions.

## Upload PDF Material

Navigation:

`Course > Lesson > Attach File`

Steps:

1. Open the lesson.
2. Choose file attachment.
3. Upload the PDF.
4. Add a clear file title.
5. Save.
6. Test download or view access.

[Screenshot: PDF upload field]

## Upload Video Material

Possible options:

| Option | Use Case |
|---|---|
| Direct video upload | Small internal videos |
| Embedded video link | Internal video server or approved platform |
| External link | Only if policy allows |

Steps:

1. Open the lesson.
2. Add video content or embed link.
3. Confirm playback works.
4. Test as a learner.

[Screenshot: Video lesson editor]

## Security Recommendation

Do not upload restricted parliamentary documents into courses unless access is properly limited.

---

# 7. Course Categories

## Purpose

Categories help learners find relevant courses.

## Recommended Categories

| Category | Example Courses |
|---|---|
| Parliamentary Procedure | Rules, motions, sessions |
| Committee Work | Reports, hearings, evidence review |
| Legislative Research | Research methods, legal references |
| Ethics and Compliance | Code of conduct, disclosure |
| Digital Skills | LMS use, office tools, cybersecurity |
| Orientation | New MP and staff onboarding |

## Create a Category

Navigation:

`LMS > Course Category > New`

Steps:

1. Enter category name.
2. Add description.
3. Save.
4. Assign courses to the category.

[Screenshot: Course Category form]

---

# 8. Batches and Learning Sessions

## Purpose

Batches group learners into a training session. This is useful for pilot groups, committees, departments, or training periods.

## Batch Examples

| Batch Name | Audience |
|---|---|
| Pilot Batch - MPs Group 1 | Selected MPs |
| Committee Training - Public Accounts | Committee members |
| Staff Orientation - May 2026 | New staff |
| Digital Learning Pilot - Secretariat | Parliamentary staff |

## Create a Batch

Navigation:

`LMS > Batches > New Batch`

Steps:

1. Enter batch name.
2. Select course or program.
3. Set start date and end date.
4. Add instructors if required.
5. Add learners.
6. Save.
7. Notify participants.

[Screenshot: New Batch form]

## Recommended Batch Settings

| Setting | Recommendation |
|---|---|
| Batch name | Include audience and period |
| Start/end dates | Use realistic completion schedule |
| Instructors | Assign accountable training owner |
| Enrollment | Use official user list |

---

# 9. Student Enrollment

## Purpose

Enrollment gives learners access to a course or batch.

## Enroll a User in a Course

Navigation:

`LMS > Course > Open Course > Enroll Students`

Steps:

1. Open the course.
2. Click enrollment option.
3. Search user by name or email.
4. Add user.
5. Save.
6. Confirm user can see the course.

[Screenshot: Enroll Students dialog]

## Enroll a Group Through Batch

Navigation:

`LMS > Batches > Open Batch > Add Students`

Steps:

1. Open the batch.
2. Add multiple users.
3. Save.
4. Confirm learner list.

[Screenshot: Batch enrollment list]

## Enrollment Recommendations

| Scenario | Recommended Method |
|---|---|
| One learner | Direct course enrollment |
| Committee training | Batch enrollment |
| Staff orientation | Batch enrollment |
| Pilot group | Batch enrollment |

---

# 10. Assessments and Quizzes

## Purpose

Quizzes check learner understanding and can support course completion requirements.

## Create a Quiz

Navigation:

`Course > Chapter or Lesson > Add Quiz`

Steps:

1. Open the course.
2. Choose the chapter or lesson.
3. Click Add Quiz.
4. Enter quiz title.
5. Add questions.
6. Select correct answers.
7. Set passing score if available.
8. Save.
9. Preview and test.

[Screenshot: Quiz creation page]

## Question Types

Common question types may include:

| Type | Use Case |
|---|---|
| Multiple Choice | Best for quick assessment |
| True/False | Good for policy checks |
| Short Answer | Useful for reflection |

## Parliamentary Quiz Examples

| Topic | Example Question |
|---|---|
| Procedure | What is the purpose of a committee hearing? |
| Ethics | Which action should be reported as a conflict of interest? |
| Digital Skills | Which password practice is safest? |

## Quiz Best Practices

Keep questions clear.  
Avoid trick questions.  
Use official parliamentary terminology.  
Review answers before publishing.

---

# 11. Certificates

## Purpose

Certificates provide proof of completion for internal training.

## How Certificates Work

Certificates are usually issued after a learner completes required course activities. Configuration may depend on LMS version and course settings.

## Recommended Certificate Usage

| Training Type | Certificate Recommendation |
|---|---|
| Orientation | Certificate recommended |
| Compliance training | Certificate recommended |
| Optional resource course | Certificate optional |
| Committee briefing | Certificate optional |

## Certificate Admin Steps

Navigation:

`LMS > Certificates` or `Course > Certificate Settings`

Steps:

1. Confirm course completion rules.
2. Configure certificate template if available.
3. Test with one pilot learner.
4. Confirm name and course title appear correctly.
5. Approve for use.

[Screenshot: Certificate settings]

## Warning

Do not issue certificates for incomplete courses or unapproved training programs.

---

# 12. Notifications

## Purpose

Notifications inform learners about enrollment, course updates, assignments, sessions, and completion reminders.

## Notification Examples

| Notification | Audience |
|---|---|
| Course enrollment | Learners |
| Batch start reminder | Learners and instructor |
| Quiz reminder | Learners |
| Certificate issued | Learner |
| Course update | Enrolled learners |

## Manage Notifications

Navigation:

`Desk > Search > Notification`

Steps:

1. Open existing notification.
2. Review trigger condition.
3. Review message text.
4. Confirm recipients.
5. Save.
6. Test with pilot account.

[Screenshot: Notification form]

## Recommendation

For pilot phase, keep notifications simple. Too many messages can confuse users.

---

# 13. Progress Tracking

## Purpose

Progress tracking helps training administrators monitor course completion and learner engagement.

## Track Learner Progress

Navigation:

`LMS > Statistics` or course progress section

Steps:

1. Open LMS dashboard.
2. Review course completion statistics.
3. Open course-specific progress.
4. Filter by batch or learner.
5. Export if needed.

[Screenshot: LMS statistics page]

## What to Monitor

| Metric | Meaning |
|---|---|
| Course completion | Learners who finished course |
| Quiz score | Assessment performance |
| Lesson progress | Learning activity completion |
| Batch progress | Group training status |
| Inactive learners | Users who have not started |

---

# 14. Reports and Analytics

## Purpose

Reports help leadership and training teams understand training adoption and completion.

## Recommended Pilot Reports

| Report | Purpose |
|---|---|
| Enrolled users by course | Track participation |
| Course completion summary | Track progress |
| Quiz result report | Assess understanding |
| Batch progress report | Monitor group training |
| Inactive learner list | Follow up with users |

## How to Use Reports

Navigation:

`Desk > Reports` or `LMS > Statistics`

Steps:

1. Open report.
2. Apply date or course filter.
3. Review records.
4. Export if allowed.
5. Share only with authorized users.

[Screenshot: Course progress report]

## Data Protection Warning

Learner progress and assessment scores should be treated as internal data.

---

# 15. Internal Resource Management

## Purpose

Internal resources include PDFs, policy documents, videos, guides, and reference materials used for parliamentary learning.

## Resource Types

| Resource | Example |
|---|---|
| PDF | Rules of procedure guide |
| Video | Recorded training session |
| Link | Internal intranet resource |
| Presentation | Training slides |
| Template | Committee report template |

## Management Rules

1. Use clear names.
2. Add version numbers when needed.
3. Avoid duplicate uploads.
4. Restrict confidential materials.
5. Review resources before publication.

## Recommended Naming Standard

`Subject - Audience - Version - Date`

Example:

`Committee Reporting Guide - Staff - v1 - 2026-05`

---

# 16. Committee-Based Access

## Purpose

Committee-based access limits learning content to relevant committee members or staff.

## Recommended Access Model

| Committee Content | Recommended Access |
|---|---|
| Public orientation | All internal users |
| Committee-specific training | Committee members only |
| Sensitive documents | Restricted group only |
| Staff operational training | Staff roles only |

## Implementation Options

Depending on LMS version and configuration, access can be handled through:

1. Batches for committee groups.
2. Course enrollment for selected users.
3. User roles for broader permissions.
4. Private course settings if available.

## Example Workflow

1. Create course: Public Accounts Committee Training.
2. Create batch: PAC Members - 2026.
3. Add only committee members.
4. Enroll batch in the course.
5. Confirm non-members cannot access the course.

[Screenshot: Committee batch enrollment]

---

# 17. Private and Internal Access

## Purpose

The platform is intended for internal parliamentary use. Public access should be limited.

## Recommended Settings

| Setting | Recommendation |
|---|---|
| Self registration | Disabled unless approved |
| Guest access | Disabled for internal courses |
| Public courses | Avoid for internal materials |
| User creation | Admin-controlled |
| External links | Approved sources only |

## Access Checklist

1. Confirm only approved users can log in.
2. Confirm private course access.
3. Test with learner account.
4. Test with unauthorized account.
5. Review guest access settings.

[Screenshot: Course access settings]

---

# 18. Sidebar and Menu Customization

## Purpose

Menu customization makes the LMS easier for MPs and staff to use.

## Safe Customization

You can safely change visible labels such as:

| Original | Example Replacement |
|---|---|
| Frappe Learning | Hluttaw Digital Learning Platform |
| Learning | Digital Learning |
| Getting started | Training Start Guide |

## Avoid Changing

Do not change internal DocType names, app names, or source folder names.

Avoid changing:

| Internal Item | Reason |
|---|---|
| frappe | Core framework |
| lms | Main LMS app |
| payments | Required dependency |
| DocType names | May break updates |
| Source files directly | May be overwritten during upgrade |

## Recommended Upgrade-Safe Method

1. Change database labels through setup configuration or custom fixtures.
2. Use Website Settings and System Settings for branding.
3. Use translation files or custom app for deep text changes.
4. Avoid editing core LMS source files directly.

---

# 19. Localization and Myanmar Language

## Purpose

Myanmar language support helps MPs and staff access training content in familiar language.

## Content Localization

Recommended approach:

| Area | Recommendation |
|---|---|
| Course titles | English/Myanmar or bilingual |
| Lesson content | Myanmar for learner-facing courses |
| Legal terms | Use official approved translation |
| Admin menus | Keep English if admins are trained |
| Certificates | Follow official language policy |

## Create Myanmar Content

Steps:

1. Create course title in Myanmar or bilingual format.
2. Add lesson text in Myanmar.
3. Upload Myanmar PDFs where required.
4. Test display on desktop and mobile.
5. Confirm fonts render correctly.

[Screenshot: Myanmar lesson content]

## Myanmar Language Warning

Use Unicode Myanmar text. Avoid legacy fonts or non-Unicode encoding.

---

# 20. Login with Microsoft and SSO Overview

## Purpose

Single Sign-On allows users to log in using official Microsoft accounts or another identity provider.

## SSO Benefits

| Benefit | Explanation |
|---|---|
| Easier login | Users use official accounts |
| Better security | Central password policy |
| Faster offboarding | Disable account centrally |
| Auditability | Login access can be reviewed |

## SSO Options

Possible options include:

1. Microsoft Entra ID / Azure AD.
2. Keycloak as identity broker.
3. Authentik as identity provider.
4. Frappe Social Login Key configuration.

## Recommended Pilot Approach

For pilot phase:

1. Start with local accounts for controlled testing.
2. Prepare Microsoft login separately.
3. Test SSO with 2-3 pilot users.
4. Roll out SSO only after stable login testing.

[Screenshot: Social Login Key settings]

## SSO Warning

Do not disable administrator password login until SSO has been fully tested and a fallback admin account exists.

---

# 21. Backup Recommendations

## Purpose

Backups protect course data, user data, uploaded files, progress, and certificates.

## What to Back Up

| Item | Reason |
|---|---|
| Database | Users, courses, progress, settings |
| Private files | Internal PDFs and attachments |
| Public files | Logos, images, course media |
| Configuration | Environment and compose configuration |
| Custom branding scripts | Reproducibility |

## Recommended Backup Schedule

| Environment | Frequency |
|---|---|
| Pilot | Daily or before major changes |
| Production | Daily minimum |
| Before upgrade | Always |
| Before rebuild | Always |

## Backup Validation

Backups are useful only if restore is tested.

Recommended:

1. Take backup.
2. Restore to test environment.
3. Confirm login works.
4. Confirm courses and files exist.
5. Confirm learner progress exists.

---

# 22. Best Practices

## Administration Best Practices

1. Use named admin accounts.
2. Limit System Manager role.
3. Keep course ownership clear.
4. Review content before publishing.
5. Use batches for groups.
6. Test as learner before rollout.
7. Keep backup before upgrade.
8. Document every configuration change.

## Course Design Best Practices

1. Use short lessons.
2. Use clear course objectives.
3. Use simple language.
4. Add quizzes only where useful.
5. Use official terminology.
6. Avoid long PDFs as the only learning method.

## Security Best Practices

1. Use strong passwords.
2. Use official email addresses.
3. Disable unused users.
4. Avoid public sharing of internal materials.
5. Review role assignments regularly.
6. Use HTTPS in production.
7. Use SSO when ready.

---

# 23. Pilot Deployment Workflow

## Purpose

The pilot workflow helps the organization test LMS usage before full production rollout.

## Pilot Phases

| Phase | Activity |
|---|---|
| Phase 1 | Technical setup and branding |
| Phase 2 | Admin training |
| Phase 3 | Create pilot courses |
| Phase 4 | Enroll small user group |
| Phase 5 | Collect feedback |
| Phase 6 | Improve content and workflow |
| Phase 7 | Prepare production rollout |

## Recommended Pilot Group

| Group | Size |
|---|---|
| Training Admins | 2-5 users |
| MPs | 5-10 users |
| Parliamentary Staff | 10-20 users |
| Committee Members | 1 committee group |

## Pilot Success Criteria

1. Users can log in.
2. Users can access assigned courses.
3. Users can complete lessons.
4. Quizzes work as expected.
5. Admins can track progress.
6. Reports are understandable.
7. Branding is acceptable.
8. No unauthorized access is observed.

---

# 24. User Guide

## For MPs and Parliamentary Staff

### Log In

1. Open the platform URL.
2. Enter username/email.
3. Enter password or use SSO if available.
4. Click Login.

[Screenshot: Login page]

### Find Assigned Courses

Navigation:

`LMS Home > Courses`

Steps:

1. Click Courses.
2. Review available or assigned courses.
3. Click a course.
4. Start the first lesson.

[Screenshot: Courses page]

### Complete a Lesson

1. Open the course.
2. Select lesson.
3. Read text or watch video.
4. Download attached material if needed.
5. Mark lesson complete if required.
6. Continue to next lesson.

[Screenshot: Lesson view]

### Take a Quiz

1. Open quiz.
2. Read instructions.
3. Answer all questions.
4. Submit.
5. Review score if available.

[Screenshot: Quiz page]

### View Progress

Navigation:

`LMS Home > Course > Progress`

Learners can check completed lessons, remaining lessons, and quiz status.

### Download Certificate

If certificate is enabled:

1. Complete all required course activities.
2. Open course completion page.
3. Download certificate if available.

[Screenshot: Certificate download]

---

# 25. Security and Permissions Guide

## Role Principles

Use least privilege. A user should receive only the access needed for their work.

## Recommended Permissions

| User Type | Access |
|---|---|
| Super Admin | Full technical and LMS configuration |
| Training Admin | Course, lesson, batch, quiz, enrollment management |
| MP | Learner access only |
| Staff | Learner access only unless assigned admin duty |
| Committee Member | Learner access plus committee-specific courses |

## Account Management

1. Create individual accounts.
2. Disable users who leave.
3. Review inactive accounts.
4. Avoid shared accounts.
5. Use strong passwords or SSO.

## Sensitive Content Rules

1. Use private courses for internal material.
2. Avoid public access for committee documents.
3. Confirm permissions before uploading confidential files.
4. Do not email sensitive learning links externally.

---

# 26. Troubleshooting Guide

## User Cannot Log In

Check:

1. User account is enabled.
2. Email is correct.
3. Password is reset if needed.
4. SSO configuration is working if SSO is enabled.
5. User has correct roles.

## User Cannot See Course

Check:

1. User is enrolled.
2. User is in correct batch.
3. Course is published.
4. Course is not restricted to another group.
5. User has learner role.

## Course Shows Old Name

Check:

1. Desktop Icon label.
2. Course title.
3. Website Settings.
4. Browser cache.
5. Frappe cache.

Ask user to hard refresh:

`Ctrl + Shift + R`

## Uploaded PDF Not Visible

Check:

1. File uploaded successfully.
2. Lesson was saved.
3. User has course access.
4. File is not private beyond user permission.

## Quiz Score Not Showing

Check:

1. Quiz is published.
2. User submitted quiz.
3. Passing score is configured.
4. Progress calculation has updated.

## Branding Still Shows Frappe Learning

Possible sources:

| Location | Fix |
|---|---|
| Desktop Icon | Change Desktop Icon label |
| Demo course | Rename course title and description |
| Getting started panel | May require translation or frontend override |
| Email templates | Update notification/email templates |
| Source translation string | Use translation/custom app approach |

---

# 27. Deployment Checklist

## Before Pilot

| Item | Done |
|---|---|
| LMS installed without ERPNext |  |
| Payments dependency installed |  |
| Branding applied |  |
| Admin password changed |  |
| Test users created |  |
| Pilot courses created |  |
| PDF/video upload tested |  |
| Course enrollment tested |  |
| Progress tracking tested |  |
| Backup tested |  |

## Before Production

| Item | Done |
|---|---|
| Real domain configured |  |
| HTTPS enabled |  |
| Strong passwords configured |  |
| Default admin disabled or secured |  |
| SSO tested if required |  |
| Public access reviewed |  |
| Role permissions reviewed |  |
| Backup automation enabled |  |
| Restore test completed |  |
| Upgrade process documented |  |
| Production support owner assigned |  |

## Post-Deployment

| Item | Frequency |
|---|---|
| Review users and roles | Monthly |
| Review backups | Weekly |
| Test restore | Quarterly |
| Review course quality | Each training cycle |
| Review security settings | Monthly |
| Review feedback | Pilot and quarterly |

---

# Final Notes

The Hluttaw Digital Learning Platform should remain simple during the pilot phase. Focus on stable access, useful courses, clear roles, and measurable learning progress.

Avoid deep source-code changes during pilot. Use upgrade-safe configuration, database labels, fixtures, translations, or a small custom app only when repeated branding or localization changes must survive updates.

