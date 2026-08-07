# MinIO S3 Object Storage Integration Guide for Frappe

This guide explains how to integrate MinIO S3 Object Storage into your Frappe stack (`my-frappe-setup`) to store attachments, PDFs, and files on a dedicated storage server instead of the local container volume.

---

## 1. Prerequisites

Before starting, ensure your MinIO server (`my-minio-setup`) is running on your network/VM and you have access to:
- **MinIO S3 API Endpoint**: e.g., `http://<minio-ip>:9000` (or `http://host.docker.internal:9000` for local testing)
- **Access Key**: e.g., `admin`
- **Secret Key**: e.g., `ChangeThisStrongPassword123!`
- **Public Bucket**: e.g., `app-public`
- **Private Bucket**: e.g., `app-private`

---

## 2. Configuration Steps

### Step 1: Check out the Branch
Navigate to the `docker-setup` directory and ensure you are on the S3 integration branch:
```bash
cd /home/hnna/my-frappe-setup/docker-setup
git checkout feature/minio-s3-integration
```

---

### Step 2: Configure Environment Variables (`.env`)
Open `/home/hnna/my-frappe-setup/docker-setup/.env` (or copy from `.env.example` if it doesn't exist) and append the following variables:

```env
# MinIO S3 Object Storage Configuration
S3_ENDPOINT_URL=http://<minio-server-ip>:9000
S3_ACCESS_KEY=admin
S3_SECRET_KEY=ChangeThisStrongPassword123!
S3_BUCKET_NAME=app-public
S3_PRIVATE_BUCKET_NAME=app-private
```

> **Note**: For local development on the same host where both stacks run on Docker, set `S3_ENDPOINT_URL=http://host.docker.internal:9000`.

---

### Step 3: Verify `apps.json` contains `frappe_s3_attachment`
Open `my-frappe-setup/docker-setup/apps.json` and verify the S3 app is configured:

```json
  {
    "name": "frappe_s3_attachment",
    "url": "https://github.com/zerodhatech/frappe-attachments-s3.git",
    "branch": "master",
    "is_custom": false
  }
```

---

### Step 4: Run Automated Setup Script
Run `setup.sh` to rebuild the Docker image containing the `frappe_s3_attachment` app, provision the containers, and automatically inject S3 configuration settings:

```bash
./setup.sh
```

**What happens behind the scenes**:
1. `setup.sh` detects `frappe_s3_attachment` in `apps.json` and installs it in the custom Docker image.
2. The `apply_s3_storage_config()` function in `setup.sh` executes and registers S3 endpoint, keys, and buckets in Frappe site config (`site_config.json`):
   ```json
   "s3_endpoint_url": "http://<minio-server-ip>:9000",
   "s3_access_key": "admin",
   "s3_secret_key": "ChangeThisStrongPassword123!",
   "s3_bucket": "app-public",
   "s3_private_bucket": "app-private"
   ```

---

## 3. Testing S3 Storage Integration

1. Log into Frappe Desk UI (`http://localhost:8787`).
2. Search for and navigate to **File List** (`/desk#List/File`).
3. Click **New** or upload an attachment to any document (e.g. a Committee, Bill, or Law).
4. Upload any PDF, Image, or text file.
5. Log into MinIO Console UI (`http://localhost:9001`).
6. Click **Buckets** and open your configured public/private bucket.
7. Confirm that the uploaded file is successfully transferred to your S3 storage bucket.
