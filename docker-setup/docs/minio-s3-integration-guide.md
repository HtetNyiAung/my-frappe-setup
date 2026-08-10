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
Open `.env` (or copy from `.env.example` if it doesn't exist) and set the S3 variables:

```env
# MinIO S3 Object Storage Configuration
S3_STORAGE_ENABLED=true
S3_ENDPOINT_URL=http://<minio-server-ip>:9000
S3_ACCESS_KEY=admin
S3_SECRET_KEY=ChangeThisStrongPassword123!
S3_REGION=us-east-1
S3_BUCKET_NAME=app-public
# Reserved for a future two-bucket integration; the current app does not use it.
S3_PRIVATE_BUCKET_NAME=app-private
```

> **Note**: For local development on the same host where both stacks run on Docker, set `S3_ENDPOINT_URL=http://host.docker.internal:9000`.

`S3_STORAGE_ENABLED` is the storage backend switch:

| Value | Behavior |
|---|---|
| `false` | Use Frappe local storage (`/files` and `/private/files`). This is the default in `.env.example`. |
| `true` | Validate MinIO and install/configure `frappe_s3_attachment` for the site. |

The setup script accepts `true/false`, `on/off`, `yes/no`, and `1/0`, then normalizes the value to `true` or `false`.

---

### Step 3: Verify `apps.json` contains `frappe_s3_attachment`
Open `apps.json` and verify the S3 app is configured:

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
Run `setup.sh` to rebuild the Docker image, provision containers, and automatically configure S3 storage:

```bash
./setup.sh
```

**What happens behind the scenes**:
1. The custom image contains `frappe_s3_attachment`, so S3 can be enabled without changing third-party source code.
2. With S3 enabled, `generate_compose_override()` injects `AWS_ENDPOINT_URL` into the Frappe containers.
3. Before the S3 hooks are activated, setup verifies the endpoint, credentials, and configured bucket with `HeadBucket`.
4. `apply_s3_storage_config()` writes credentials and the bucket name to the `S3 File Attachment` DocType.
5. With S3 disabled, the app is excluded from new site installation and Frappe keeps its normal local-file behavior.

### Switching an Existing Site Back to Local Storage

Setting `S3_STORAGE_ENABLED=false` is safe only when the site has no S3-backed `File` records. During setup:

1. The site is checked for private S3 handler URLs and public URLs under the configured bucket.
2. If any are found, setup stops without uninstalling the S3 app. Migrate the objects and update their `File` records first.
3. If none are found, setup uninstalls `frappe_s3_attachment` from the site, removing its upload hooks. Future uploads use local storage.

Disabling S3 does not download or migrate existing objects automatically.

---

## 3. Dependency Verification

The custom image should install `boto3` as an application dependency. Verify it inside the backend container:

```bash
docker compose -f pwd-with-apps.yml exec backend \
  /home/frappe/frappe-bench/env/bin/python -c "import boto3; print(boto3.__version__)"
```

If this fails, rebuild the custom image and confirm the S3 application's dependencies were installed. Do not install packages into the container's system Python.

---

## 4. How S3 Configuration Works (No Manual UI Setup Required)

`setup.sh` automatically handles all S3 configuration:

| What | How | Where |
|---|---|---|
| **MinIO Endpoint** | `AWS_ENDPOINT_URL` env var injected into Docker containers | `docker-compose.override.yml` |
| **AWS Key / Secret** | Written to `S3 File Attachment` DocType via `bench console` | Frappe Database |
| **Bucket / Region** | Written to `S3 File Attachment` DocType via `bench console` | Frappe Database |

> **Verify in Desk UI**: After `setup.sh` completes, go to `http://localhost:8787/desk/s3-file-attachment/S3%20File%20Attachment` to confirm the credentials are populated.

---

## 5. Testing S3 Storage Integration

1. Log into Frappe Desk UI (`http://localhost:8787`).
2. Search for and navigate to **File List** (`/desk#List/File`).
3. Click **New** or upload an attachment to any document (e.g. a Committee, Bill, or Law).
4. Upload any PDF, Image, or text file.
5. Log into MinIO Console UI (`http://localhost:9001`).
6. Click **Buckets** and open the bucket configured in `S3_BUCKET_NAME`.
7. Confirm that the uploaded file is successfully transferred to your S3 storage bucket.

### Bucket Model Limitation

The current `frappe_s3_attachment` application has one `bucket_name` setting. It stores both public and private uploads in that bucket and does not read `S3_PRIVATE_BUCKET_NAME`. Therefore, `app-public` and `app-private` are not yet a true two-bucket split in this setup.

For permission-sensitive parliamentary attachments, do not rely on an anonymously downloadable bucket for private files. A true public/private bucket split requires a separate application integration and portal-file compatibility work.

---

## 6. Troubleshooting

### `ModuleNotFoundError: No module named 'boto3'`

Rebuild the custom image and verify the dependency inside Frappe's virtual environment:

```bash
./setup.sh --rebuild
docker compose -f pwd-with-apps.yml exec backend \
  /home/frappe/frappe-bench/env/bin/python -c "import boto3; print(boto3.__version__)"
```

### `InvalidAccessKeyId` Error
This means boto3 is connecting to AWS S3 instead of MinIO. Verify `AWS_ENDPOINT_URL` is set:
```bash
docker compose -f pwd-with-apps.yml exec backend printenv AWS_ENDPOINT_URL
```
If empty, re-run `./setup.sh` to regenerate the Docker Compose override.

### `NoSuchBucket` or S3 preflight failure

The bucket in `S3_BUCKET_NAME` does not exist in the MinIO instance currently serving `S3_ENDPOINT_URL`, or the configured credentials cannot access it. Create/restore the exact bucket and verify its policy before rerunning `setup.sh`. Setup intentionally stops before enabling S3 upload hooks.

### Setup refuses `S3_STORAGE_ENABLED=false`

The site still contains S3-backed `File` records. Keep S3 enabled until those objects are migrated to local storage and their `File` URLs are updated. This guard prevents existing attachments from becoming inaccessible.

### S3 File Attachment settings are empty in Desk UI
Re-run `./setup.sh` — the `apply_s3_storage_config()` function writes credentials to the DocType automatically.
