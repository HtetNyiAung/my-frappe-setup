# Legacy Update Command

`update.sh` is retained only for backward compatibility. It now forwards its
arguments to:

```bash
./deploy.sh apply
```

For new operational procedures and automation, use the explicit deployment
workflow:

```bash
./deploy.sh check
./deploy.sh plan
./deploy.sh apply
./deploy.sh verify
```

See [Application Deployment Guide](deploy.md) for safety behaviour and failure
recovery. See [Runtime Operations Guide](../operations/operations.md) for migration, cache,
restart, status, logs, and Maintenance Mode commands.
