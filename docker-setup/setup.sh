#!/usr/bin/env bash
# Frappe ERPNext + HRMS + Insights - Docker Setup Script
# Run this from the docker-setup directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Frappe ERPNext + HRMS + Insights Setup"
echo "=========================================="

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Clone frappe_docker if not present
FRAPPE_DOCKER_DIR="$SCRIPT_DIR/frappe_docker"
if [ ! -d "$FRAPPE_DOCKER_DIR" ]; then
    echo ""
    echo "Cloning frappe_docker repository..."
    git clone https://github.com/frappe/frappe_docker.git "$FRAPPE_DOCKER_DIR"
else
    echo ""
    echo "frappe_docker already cloned. Pulling latest..."
    (cd "$FRAPPE_DOCKER_DIR" && git pull)
fi

# Build custom image with ERPNext, HRMS, Insights
echo ""
echo "Building custom Docker image (this may take 15-30 minutes)..."
echo "Apps: ERPNext, HRMS, Insights"
echo ""

# Create apps.json in frappe_docker for build context
APPS_JSON="$FRAPPE_DOCKER_DIR/apps.json"
cp "$SCRIPT_DIR/apps.json" "$APPS_JSON"

# Build - must run from frappe_docker root (needs resources/, images/)
cd "$FRAPPE_DOCKER_DIR"

# Base64 encode apps.json (Linux/macOS compatible)
if [[ "$OSTYPE" == "darwin"* ]]; then
    APPS_JSON_BASE64=$(base64 -i apps.json | tr -d '\n')
else
    APPS_JSON_BASE64=$(base64 -w 0 apps.json)
fi

echo "Building image from frappe_docker (context: $FRAPPE_DOCKER_DIR)..."
docker build \
    --build-arg FRAPPE_BRANCH=version-16 \
    --build-arg APPS_JSON_BASE64="$APPS_JSON_BASE64" \
    --tag frappe-erpnext-hrms-insights:v16 \
    --file images/custom/Containerfile \
    .

BUILD_EXIT=$?
cd "$SCRIPT_DIR"

if [ $BUILD_EXIT -ne 0 ]; then
    echo ""
    echo "Build failed. Check the output above for errors."
    exit 1
fi

if ! docker image inspect frappe-erpnext-hrms-insights:v16 > /dev/null 2>&1; then
    echo "Error: Image was not created successfully."
    exit 1
fi

echo ""
echo "=========================================="
echo "Image built successfully!"
echo "Starting containers..."
echo "=========================================="

# Start with our custom compose file
docker compose -f pwd-with-apps.yml up -d

echo ""
echo "Containers are starting. Wait 3-5 minutes for site creation."
echo ""
echo "Monitor progress with:"
echo "  docker compose -f pwd-with-apps.yml logs -f create-site"
echo ""
echo "When ready, open: http://localhost:8080"
echo "  Username: Administrator"
echo "  Password: admin"
echo ""
echo "To stop: docker compose -f pwd-with-apps.yml down"
echo "=========================================="
