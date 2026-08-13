# Logs Script (`logs.sh`)

The `logs.sh` script is a utility for real-time monitoring of your entire application stack.

## What it does

It tails the output logs from **every container** in both of your core stacks:
1.  **Frappe Stack**: Containers defined in `pwd-with-apps.yml` (backend, frontend, workers, redis, etc.).
2.  **Keycloak Stack**: Containers defined in `docker-compose.keycloak.yml` (keycloak, postgres-db).

## Usage

```bash
chmod +x logs.sh
./logs.sh
```

-   **Press `Ctrl+C` to stop** streaming the logs.
-   The script only shows the last 100 lines by default to prevent overwhelming your terminal.

## Why use this?

Instead of running two separate `docker compose logs` commands, this script merges them into a single window. It is perfect for debugging:
-   SSO Redirect failures (viewing both Keycloak and Frappe logs together).
-   Background task failures.
-   Start-up errors or connectivity timeouts.
