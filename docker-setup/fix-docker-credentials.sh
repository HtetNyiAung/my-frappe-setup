#!/usr/bin/env bash

# Purpose: Fix Docker credential-helper errors on Linux/WSL servers.
# Common error:
#   error getting credentials - err: exit status 1, out: ``
#
# This backs up ~/.docker/config.json and replaces it with a simple config
# that does not use credsStore/credHelpers. Public image pulls do not require
# Docker Hub login unless rate limits are reached.

set -e

DOCKER_CONFIG_DIR="${DOCKER_CONFIG:-$HOME/.docker}"
DOCKER_CONFIG_FILE="$DOCKER_CONFIG_DIR/config.json"

echo "Checking Docker credential config..."

mkdir -p "$DOCKER_CONFIG_DIR"

if [ -f "$DOCKER_CONFIG_FILE" ]; then
    BACKUP_FILE="$DOCKER_CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backing up old Docker config to: $BACKUP_FILE"
    mv "$DOCKER_CONFIG_FILE" "$BACKUP_FILE"
fi

cat > "$DOCKER_CONFIG_FILE" <<'JSON'
{
  "auths": {}
}
JSON

chmod 600 "$DOCKER_CONFIG_FILE"

echo "Docker credential config fixed."
echo "Testing public image pulls..."

docker pull redis:6.2-alpine
docker pull mariadb:10.6

echo ""
echo "Done. You can now run:"
echo "  cd $(pwd)"
echo "  ./setup.sh --rebuild"
