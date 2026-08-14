# Database Client Access အသုံးပြုနည်း

ဒီ guide က Frappe Docker setup ထဲက bundled Local MariaDB ကို MySQL Workbench
သို့မဟုတ် အခြား Database Client ကနေ ချိတ်ဆက်အသုံးပြုနည်းကို ရှင်းပြထားပါတယ်။

သီးခြား Database Server ကိုချိတ်လိုပါက
[External MariaDB Guide](external-database.md) ကိုအသုံးပြုပါ။

## Production အတွက် အကြံပြုထားသည့်ပုံစံ

Production မှာ Database port ကို Public Network သို့ တိုက်ရိုက်မဖွင့်ပါနှင့်။
Compose port mapping ကို အောက်ပါအတိုင်း Localhost မှာပဲ bind လုပ်ထားသင့်ပါတယ်။

```yaml
ports:
  - "127.0.0.1:3307:3306"
```

ဒီ mapping ရဲ့အဓိပ္ပာယ်က:

```text
Host 127.0.0.1:3307 -> Docker MariaDB Container:3306
```

MariaDB က Container အတွင်း `3306` ကိုသုံးပါတယ်။ Host မှာရှိပြီးသား
MySQL/MariaDB နဲ့ Port Conflict မဖြစ်စေရန် Host Port ကို `3307` သုံးထားပါတယ်။

## ချိတ်ဆက်နည်းရွေးချယ်ခြင်း

| Database Client ရှိသည့်နေရာ | အကြံပြုနည်း |
|---|---|
| Docker run နေသော Laptop/Server တစ်လုံးတည်း | Standard TCP/IP မှ `127.0.0.1:3307` |
| အခြား Administrator Laptop | Standard TCP/IP over SSH |
| Trusted Internal LAN | Private IP ဖြင့် Direct Access နှင့် Firewall restriction |
| Public Internet | Direct Access မလုပ်ရပါ; SSH Tunnel သုံးပါ |

## Same Machine Access

MySQL Workbench နဲ့ Docker က Server သို့မဟုတ် Laptop တစ်လုံးတည်းမှာရှိရင် ဒီနည်းကို
သုံးပါ။

MySQL Workbench values:

```text
Connection Method: Standard TCP/IP
Hostname: 127.0.0.1
Port: 3307
Username: root
Password: .env ထဲက MYSQL_ROOT_PASSWORD သို့မဟုတ် MARIADB_ROOT_PASSWORD
Default Schema: အလွတ်ထားပါ
```

MySQL Workbench က Host Port `3307` ကိုချိတ်ပြီး Docker က MariaDB Container ရဲ့
Port `3306` သို့ forward လုပ်ပေးပါတယ်။

## SSH Tunnel ဖြင့် Remote Laptop မှချိတ်ဆက်ခြင်း

MySQL Workbench က အခြား Laptop မှာရှိပြီး Database Port က Server ရဲ့
`127.0.0.1` မှာပဲ bind လုပ်ထားရင် ဒီနည်းကိုသုံးပါ။ Database Port ကို Network
ပေါ်မဖွင့်ဘဲ encrypted SSH connection ကနေဝင်နိုင်တာကြောင့် ဒီနည်းကို
အကြံပြုပါတယ်။

MySQL Workbench values:

```text
Connection Method: Standard TCP/IP over SSH

SSH Hostname: <SERVER_PRIVATE_IP>:22
SSH Username: <SSH_USER>
SSH Password or SSH Key File: Server SSH credential

MySQL Hostname: 127.0.0.1
MySQL Server Port: 3307
Username: root
Password: .env ထဲက MYSQL_ROOT_PASSWORD သို့မဟုတ် MARIADB_ROOT_PASSWORD
Default Schema: အလွတ်ထားပါ
```

Connection flow:

```text
Administrator Laptop / MySQL Workbench
  -> SSH Connection to App Server
  -> App Server 127.0.0.1:3307
  -> Docker MariaDB Container:3306
```

`MySQL Hostname` က SSH Server ကနေကြည့်သည့် Database address ဖြစ်ပါတယ်။ Local
Compose MariaDB အတွက် `127.0.0.1` နဲ့ published Host Port `3307` ကိုသုံးရပါမယ်။

## SSH Password သို့မဟုတ် SSH Key ဘယ်ကရမလဲ

SSH credential က Frappe Password မဟုတ်သလို Database Password လည်းမဟုတ်ပါ။
Server Login အတွက်အသုံးပြုသည့် credential ဖြစ်ပါတယ်။ အောက်ပါနေရာတစ်ခုကနေ
ရနိုင်ပါတယ်။

- Server Administrator
- Cloud Provider ရဲ့ Server Setup page
- Server ကို SSH ဝင်ရာမှာသုံးထားသည့် `.pem` သို့မဟုတ် Private Key
- Infrastructure/DevOps Team
- Server ဖန်တီးထားသူ

ဥပမာ:

```text
SSH Username: ubuntu
SSH Key File: /path/to/server-key.pem
```

သို့မဟုတ်:

```text
SSH Username: deploy
SSH Password: Server Login Password
```

အသုံးများသည့် SSH Username များ:

```text
ubuntu
debian
root
deploy
frappe
```

မှန်ကန်သည့် Username က Server Image နဲ့ Server ဖန်တီးထားပုံပေါ် မူတည်ပါတယ်။
Private SSH Key ကို Git, Chat, Email သို့မဟုတ် Screenshot ထဲ မမျှဝေပါနှင့်။

## Terminal မှ SSH Tunnel ဖွင့်ခြင်း

MySQL Workbench ထဲမှာ SSH မပြင်ဘဲ Laptop Terminal ကနေ Tunnel ဖွင့်နိုင်ပါတယ်။

Laptop မှာ run ပါ:

```bash
ssh -L 3307:127.0.0.1:3307 <SSH_USER>@<SERVER_PRIVATE_IP>
```

ဒီ Terminal ကိုဖွင့်ထားပြီး MySQL Workbench မှာ အောက်ပါ values သုံးပါ:

```text
Connection Method: Standard TCP/IP
Hostname: 127.0.0.1
Port: 3307
Username: root
Password: .env ထဲက MYSQL_ROOT_PASSWORD သို့မဟုတ် MARIADB_ROOT_PASSWORD
```

Laptop ရဲ့ Port `3307` ကို အခြား service သုံးနေပါက ပထမ `3307` ကို available
port တစ်ခုနဲ့ပြောင်းနိုင်ပါတယ်။ ဥပမာ:

```bash
ssh -L 13307:127.0.0.1:3307 <SSH_USER>@<SERVER_PRIVATE_IP>
```

ဒီအခါ MySQL Workbench Port ကို `13307` သုံးရပါမယ်။

## Internal LAN Direct Access

Trusted Office Network ထဲက Laptop တွေကို SSH Tunnel မသုံးဘဲ ချိတ်စေလိုမှသာ
Database Port ကို Server Private IP မှာ bind လုပ်ပါ။

ဥပမာ:

```yaml
ports:
  - "<SERVER_PRIVATE_IP>:3307:3306"
```

MySQL Workbench values:

```text
Hostname: <SERVER_PRIVATE_IP>
Port: 3307
Username: <LIMITED_DATABASE_USER>
Password: Database User Password
```

ဒီနည်းက `127.0.0.1` binding ထက် exposure ပိုများပါတယ်။ Firewall မှာ approved
Client IP တွေကိုပဲ Allow လုပ်ပြီး Daily Access အတွက် `root` အစား Limited User
သို့မဟုတ် Read-only User သုံးပါ။

## မအကြံပြုသည့် Broad Port Mapping

```yaml
ports:
  - "3307:3306"
```

ဒီ mapping က Host Network Interfaces အားလုံးပေါ် bind ဖြစ်နိုင်ပြီး အောက်ပါ
ပုံစံနဲ့တူပါတယ်။

```yaml
ports:
  - "0.0.0.0:3307:3306"
```

Network exposure နဲ့ Firewall rules ကို အပြည့်အဝသိရှိပြီး approved requirement
ရှိမှသာ သုံးပါ။ Public Internet အတွက် မသုံးပါနှင့်။

## Limited Read-only User အသုံးပြုခြင်း

Reporting သို့မဟုတ် Data စစ်ဆေးရန်သာလိုပါက `root` သို့မဟုတ် Frappe Runtime
User မပေးဘဲ သီးခြား Read-only User ဆောက်ပါ။ `<SITE_DB_NAME>` နဲ့ Host ကို
Environment အလိုက်အစားထိုးပါ။

```sql
CREATE USER 'report_reader'@'<CLIENT_PRIVATE_IP>'
  IDENTIFIED BY '<STRONG_READ_ONLY_PASSWORD>';

GRANT SELECT ON `<SITE_DB_NAME>`.*
  TO 'report_reader'@'<CLIENT_PRIVATE_IP>';

FLUSH PRIVILEGES;
```

ဒီ User က Data ဖတ်နိုင်ပေမယ့် Record ပြင်ခြင်းနဲ့ Schema ပြောင်းခြင်း မလုပ်နိုင်ပါ။
လိုအပ်ချက်မရှိတော့ပါက Account ကိုဖျက်ပါ။

## Security အကြံပြုချက်များ

- Production မှာ `127.0.0.1:3307:3306` နဲ့ SSH Tunnel ကိုဦးစားပေးပါ။
- MariaDB Port ကို Public Internet သို့ မဖွင့်ပါနှင့်။
- Strong Database Password သုံးပါ။
- Daily Reporting အတွက် Database `root` မသုံးပါနှင့်။
- လိုအပ်သည့် Schema နဲ့ Permission သာရသည့် Limited User သုံးပါ။
- SSH Access ကို approved Administrators တွေအတွက်သာထားပါ။
- `.env`, Password နဲ့ Private SSH Key ကို Git ထဲ commit မလုပ်ပါနှင့်။
- Customer Data ကို Screenshot သို့မဟုတ် Support Log ထဲမထည့်ပါနှင့်။

## ပြဿနာဖြေရှင်းခြင်း (Troubleshooting)

### Database Container နဲ့ Port Mapping စစ်ခြင်း

```bash
docker compose ps db
```

Local-only access အတွက် အောက်ပါ mapping မြင်ရပါမယ်:

```text
127.0.0.1:3307->3306/tcp
```

Database Logs ကြည့်ရန်:

```bash
docker compose logs db --tail 200
```

### MySQL Workbench ချိတ်မရခြင်း

- Docker Containers running ဖြစ်မဖြစ်စစ်ပါ။
- Compose Port Mapping မှန်မမှန်စစ်ပါ။
- Host မှာ `3307` သုံးပြီး Container အတွင်းမှာ `3306` သုံးတာ မရောပါနှင့်။
- `.env` ထဲက Database Password မှန်မမှန်စစ်ပါ။
- SSH Tunnel သုံးထားပါက SSH Login ကိုအရင်စမ်းပါ။
- Direct LAN Access သုံးထားပါက Firewall မှာ Client IP Allow ဖြစ်မဖြစ်စစ်ပါ။

### SSH Tunnel ရသော်လည်း Database Access Denied ဖြစ်ခြင်း

SSH Connection အောင်တာက Database Authentication အောင်တာမဟုတ်ပါ။ MySQL
Username, Password နဲ့ MariaDB Account ရဲ့ Host restriction ကို သီးခြားစစ်ပါ။

### External Database Server ချိတ်လိုခြင်း

External MariaDB ရဲ့ Port, User Host နဲ့ Firewall က Local Container နဲ့မတူပါ။
[External MariaDB Guide](external-database.md) နဲ့
[External Database First Setup Guide](external-database-ubuntu.md) ကိုလိုက်နာပါ။
