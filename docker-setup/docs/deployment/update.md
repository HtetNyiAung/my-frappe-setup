# Legacy Update Command

`update.sh` ကို Backward Compatibility အတွက်သာ ဆက်ထားသည်။ ပေးလိုက်သော
Arguments များကို အောက်ပါ command သို့ လွှဲပေးသည်။

```bash
./deploy.sh apply
```

Operation အသစ်နှင့် Automation အတွက် Explicit Deployment workflow ကိုသုံးပါ။

```bash
./deploy.sh check
./deploy.sh plan
./deploy.sh apply
./deploy.sh verify
```

Safety behavior နှင့် Failure recovery အတွက် [Application Deployment
လမ်းညွှန်](deploy.md) ကိုဖတ်ပါ။ Migration, Cache, Restart, Status, Logs နှင့်
Maintenance Mode အတွက် [Runtime Operations လမ်းညွှန်](../operations/operations.md)
ကို ဖတ်ပါ။
