#!/usr/bin/env bash
# Purpose: Update Frappe apps and framework versions safely
set -e

# --- 1. Load Environment Variables ---
if [ -f .env ]; then 
    export $(grep -v '^#' .env | sed 's/\s*#.*$//' | xargs)
    echo "Environment variables loaded from .env"
else 
    echo "Error: .env file missing. Update aborted."; exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "🚀 STARTING UPDATE PROCESS: $STACK_ID"
echo "=========================================="

# --- 2. Step 1: Safety Backup ---
echo "📦 Step 1: Creating Safety Backup..."
if [ -f "./backup.sh" ]; then
    ./backup.sh
else
    echo "⚠️ Warning: backup.sh not found. Proceeding without backup (not recommended)."
fi

# --- 3. Step 2: Rebuild Image ---
echo "🛠️ Step 2: Rebuilding Docker Image with latest app versions..."
# We reuse the setup.sh logic to build but we don't need to re-provision the site
if [ -f "./setup.sh" ]; then
    # We run setup.sh which handles the build and the migrations automatically
    ./setup.sh
else
    echo "Error: setup.sh not found. Cannot proceed with build."
    exit 1
fi

echo "=========================================="
echo "✅ UPDATE COMPLETED SUCCESSFULLY"
echo "=========================================="
echo "Your Frappe site $SITE_DOMAIN is now running the latest versions."
echo "Check logs if you see any issues: ./logs.sh"
echo "=========================================="
