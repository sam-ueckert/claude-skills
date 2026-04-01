# GCP Onboarding — Service Account with JSON Key

This guide creates a GCP Service Account, attaches a custom compute role, and downloads a JSON key file the skill can use. By the end, you'll have a `GOOGLE_APPLICATION_CREDENTIALS` path pointing to the key.

---

## Role Used

The custom role from `schemas/gcp-compute-role.yaml` grants:
- **Compute Engine:** list, get, create, delete, start, stop instances; manage tags, labels, metadata, firewalls, and read networks/subnets
- **Cloud Run:** list, get services; run jobs
- **Cloud Functions:** list, get, call functions

This follows the principle of least privilege — no broad `compute.admin` or `owner` roles.

---

## Option A: GCP Console

### 1. Create a Custom IAM Role

1. Sign in to the [GCP Console](https://console.cloud.google.com)
2. Navigate to **IAM & Admin** → **Roles** → **Create Role**
3. Fill in:
   - **Title:** `Agent Compute Automation`
   - **Description:** `Least-privilege role for compute automation via AI agent skills`
   - **Role launch stage:** `General Availability`
4. Click **Add Permissions** and add each permission from `schemas/gcp-compute-role.yaml`'s `includedPermissions` list
5. Click **Create**

### 2. Create the Service Account

1. Navigate to **IAM & Admin** → **Service Accounts** → **Create Service Account**
2. Fill in:
   - **Service account name:** `agent-compute`
   - **Service account ID:** `agent-compute` (auto-filled)
   - **Description:** `Compute automation service account for AI agent skills`
3. Click **Create and Continue**

### 3. Assign the Custom Role

1. On the "Grant this service account access to project" step, click **Select a role**
2. Search for `Agent Compute Automation` and select it
3. Click **Continue** → **Done**

### 4. Download the JSON Key

1. In the Service Accounts list, click on `agent-compute`
2. Go to the **Keys** tab → **Add Key** → **Create new key**
3. Select **JSON** → **Create**

> ⚠️ **ONE-TIME WARNING:** The JSON key file is downloaded once. GCP does not store it and has no way to re-download it. If you lose it, you must delete the key and create a new one. Store it securely and never commit it to version control.

4. Save the downloaded file to a secure location (e.g., `~/.config/gcloud/agent-compute-key.json`)
5. Set the environment variable:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/agent-compute-key.json"
   ```

---

## Option B: gcloud CLI

```bash
# Set variables
PROJECT_ID="your-gcp-project-id"
SA_NAME="agent-compute"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="$HOME/.config/gcloud/agent-compute-key.json"

# 1. Create the custom role from YAML
gcloud iam roles create agentComputeAutomation \
  --project="$PROJECT_ID" \
  --file=skills/cloud-provisioning/schemas/gcp-compute-role.yaml

# 2. Create the service account
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="Agent Compute Automation" \
  --description="Least-privilege compute automation for AI agent skills" \
  --project="$PROJECT_ID"

# 3. Bind the custom role to the service account
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="projects/${PROJECT_ID}/roles/agentComputeAutomation"

# 4. Create and download the JSON key
# ⚠️ This is the only time this key can be downloaded
mkdir -p "$(dirname $KEY_FILE)"
gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SA_EMAIL" \
  --project="$PROJECT_ID"

echo "Key saved to: $KEY_FILE"
echo "Set: export GOOGLE_APPLICATION_CREDENTIALS=$KEY_FILE"
```

---

## Verification

```bash
# Activate the service account credentials
gcloud auth activate-service-account \
  --key-file="$GOOGLE_APPLICATION_CREDENTIALS"

# List compute instances (empty list is fine — means auth worked)
gcloud compute instances list --project="$PROJECT_ID"

# Verify the active account
gcloud config get-value account
# Should return: agent-compute@your-project-id.iam.gserviceaccount.com

# For SDK-based verification (Python example)
python3 -c "
import google.auth
creds, project = google.auth.default()
print(f'Project: {project}')
print(f'Credentials: {type(creds).__name__}')
"
```

---

## Gotchas

### JSON Key Download Is One-Time Only
Unlike AWS, GCP doesn't show you the key content again after the initial download. The Console and CLI only let you create a new key. If you lose the file, delete the key in **IAM & Admin** → **Service Accounts** → **Keys** tab, and create a fresh one. There is no recovery path.

### Service Account Email Format
The service account email is always:
```
<sa-name>@<project-id>.iam.gserviceaccount.com
```
Project IDs can contain hyphens and numbers (e.g., `my-project-123456`). Note: this is the **project ID**, not the project **name** or **number**. Get it with `gcloud config get-value project`.

### Billing Must Be Enabled
Even read-only Compute API calls require billing to be enabled on the project. If you get `BILLING_DISABLED` or `API not enabled` errors:
1. Go to **Billing** in the console and link a billing account
2. Enable the APIs: `gcloud services enable compute.googleapis.com run.googleapis.com cloudfunctions.googleapis.com`

### Custom Role ID vs Display Name
The role **ID** used in the CLI (`agentComputeAutomation`) is separate from the **display name** (`Agent Compute Automation`). When referencing in policy bindings, use the full path:
```
projects/{project-id}/roles/agentComputeAutomation
```

### Application Default Credentials (ADC) vs Key File
Setting `GOOGLE_APPLICATION_CREDENTIALS` works for the current shell session. For persistent configuration, add it to `.bashrc`/`.zshrc`, or use:
```bash
gcloud config set auth/credential_file_override "$KEY_FILE"
```
Avoid placing the key file in a directory that gets committed to version control. Add `*.json` to `.gitignore` in any directory where you store keys.

### Key Rotation
GCP JSON keys do not expire by default, but should be rotated periodically. Check for old keys with:
```bash
gcloud iam service-accounts keys list --iam-account="$SA_EMAIL" --project="$PROJECT_ID"
```
Delete unused keys with `gcloud iam service-accounts keys delete KEY_ID --iam-account="$SA_EMAIL"`.
