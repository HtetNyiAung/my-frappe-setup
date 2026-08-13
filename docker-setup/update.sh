#!/usr/bin/env bash
# Compatibility wrapper. Use deploy.sh directly for new automation.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Notice: update.sh is deprecated; forwarding to: deploy.sh apply"
exec "$SCRIPT_DIR/deploy.sh" apply "$@"
