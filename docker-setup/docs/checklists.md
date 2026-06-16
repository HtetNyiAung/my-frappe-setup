# Frappe LMS Hosting Checklists

Use these checklists before, during, and after hosting the LMS on a real domain.

## 1. Server Checklist

- [ ] Ubuntu server is ready.
- [ ] Server has at least 2 CPU cores.
- [ ] Server has at least 4 GB RAM. 8 GB is recommended.
- [ ] Server has at least 40 GB disk space.
- [ ] SSH access is working.
- [ ] Firewall allows HTTP and HTTPS.
- [ ] Docker is installed.
- [ ] Docker Compose plugin is installed.
- [ ] Git is installed.
- [ ] `jq` is installed.
- [ ] Nginx is installed.
- [ ] Certbot is installed.

## 2. Domain Checklist

- [ ] Domain name is purchased.
- [ ] LMS subdomain is chosen, for example `lms.example.com`.
- [ ] DNS `A` record points to the server IP.
- [ ] DNS propagation is complete.
- [ ] Domain opens the server in browser.

## 3. Environment Checklist

- [ ] `.env` file is created from `.env.example`.
- [ ] `PUBLIC_URL` is set to the real HTTPS domain.
- [ ] `FRAPPE_PORT` is set.
- [ ] `BIND_ADDRESS` is set to `127.0.0.1` when using Nginx reverse proxy.
- [ ] `MYSQL_ROOT_PASSWORD` is changed from default.
- [ ] `MARIADB_ROOT_PASSWORD` is changed from default.
- [ ] `ADMIN_PASSWORD` is changed from default.
- [ ] `SITE_DOMAIN` is set correctly.
- [ ] `CUSTOM_IMAGE` name is correct.
- [ ] `apps.json` contains the required apps.

## 4. Deployment Checklist

- [ ] Project files are copied or cloned to the server.
- [ ] Scripts are executable.
- [ ] Docker image builds successfully.
- [ ] Frappe containers start successfully.
- [ ] Site is created successfully.
- [ ] Required apps are installed successfully.
- [ ] Migration completes successfully.
- [ ] LMS opens using server IP and port.
- [ ] Administrator login works.

Run:

```bash
cd docker-setup
chmod +x setup.sh backup.sh restore.sh logs.sh cleanup.sh
./setup.sh
```

Verify:

```bash
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml ps
docker compose -f pwd-with-apps.yml -f docker-compose.override.yml exec backend bench --site frontend list-apps
```

## 5. Nginx And SSL Checklist

- [ ] Nginx reverse proxy config is created.
- [ ] `proxy_pass` points to the local Frappe port.
- [ ] Nginx config test passes.
- [ ] Nginx restarts successfully.
- [ ] SSL certificate is issued with Certbot.
- [ ] HTTPS opens correctly.
- [ ] HTTP redirects to HTTPS.
- [ ] File upload works over HTTPS.

Example SSL command:

```bash
sudo certbot --nginx -d lms.example.com
```

## 6. LMS Setup Checklist

- [ ] Site branding is updated.
- [ ] System language is checked.
- [ ] Time zone is checked.
- [ ] Admin email is changed from default.
- [ ] Outbound email configured (Gmail or Outlook) — [email-outlook-setup-guide.md](./email-outlook-setup-guide.md).
- [ ] Test email sent from **Email Account** (Send Test Email).
- [ ] Forgot password email tested on login page.
- [ ] Instructor accounts are created.
- [ ] Learner accounts are created or invited.
- [ ] Courses are created.
- [ ] Lessons are created.
- [ ] PDFs are uploaded and tested.
- [ ] Programs are created if needed.
- [ ] Members are added to programs.
- [ ] Course progress tracking is tested.
- [ ] Learner login is tested.

## 7. PDF Lesson Checklist

- [ ] PDF file is uploaded in Attachments.
- [ ] File URL is copied.
- [ ] Download link is added to learner-facing Content or Body.
- [ ] PDF opens as a learner.
- [ ] Private PDF permissions are tested.
- [ ] Public PDF access is tested if using `/files/`.
- [ ] File name is clear and readable.

## 8. Backup Checklist

- [ ] Backup script runs successfully.
- [ ] Database backup is created.
- [ ] Public files backup is created.
- [ ] Private files backup is created.
- [ ] Backup folder is copied outside the server.
- [ ] Restore process is tested on a test server.

Run:

```bash
cd docker-setup
./backup.sh
```

## 9. Maintenance Checklist

- [ ] Check container health weekly.
- [ ] Check disk usage weekly.
- [ ] Check logs when users report issues.
- [ ] Run backups before updates.
- [ ] Update only after backup is complete.
- [ ] Test login after update.
- [ ] Test course lesson page after update.
- [ ] Test PDF downloads after update.

Useful commands:

```bash
cd docker-setup
./logs.sh
./cleanup.sh
./update.sh
```

## 10. Go-Live Checklist

- [ ] HTTPS domain is working.
- [ ] Admin password is secure.
- [ ] Test learner account is working.
- [ ] Test instructor account is working.
- [ ] Course content is visible to learners.
- [ ] Program members can access assigned programs.
- [ ] PDF downloads work.
- [ ] Outbound email and password reset tested — [email-outlook-setup-guide.md](./email-outlook-setup-guide.md).
- [ ] Backup is completed.
- [ ] Restore procedure is known.
- [ ] Support contact is ready for users.

## Myanmar Quick Notes

- Server Checklist = Server ပြင်ဆင်ပြီးပြီလား စစ်ရန်။
- Domain Checklist = Domain/DNS မှန်လား စစ်ရန်။
- Environment Checklist = `.env` configuration မှန်လား စစ်ရန်။
- Deployment Checklist = Frappe LMS run ဖြစ်လား စစ်ရန်။
- Nginx And SSL Checklist = HTTPS domain အတွက် စစ်ရန်။
- LMS Setup Checklist = Course, lesson, learner setup စစ်ရန်။
- Email Checklist = Gmail သို့မဟုတ် Outlook SMTP + forgot password စစ်ရန် ([guide](./email-outlook-setup-guide.md))။
- PDF Lesson Checklist = Learner PDF download လုပ်နိုင်လား စစ်ရန်။
- Backup Checklist = Data backup ရှိလား စစ်ရန်။
- Maintenance Checklist = Hosting ပြီးနောက် ပုံမှန်ထိန်းသိမ်းရန်။
- Go-Live Checklist = User တွေကိုအသုံးပြုခိုင်းမီ နောက်ဆုံးစစ်ရန်။
