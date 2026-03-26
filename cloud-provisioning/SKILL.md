---
name: cloud-provisioning
description: >
  Onboard and provision compute credentials for AWS, Azure, and GCP. Use this skill
  whenever the user needs to set up cloud credentials, create IAM users or service
  accounts, configure service principals, or provision compute access on any major
  cloud platform. Triggers on phrases like "set up AWS", "configure Azure credentials",
  "create GCP service account", "onboard to cloud", "provision compute", or any
  mention of cloud IAM, access keys, or service principals for automation purposes.
  Walks through step-by-step onboarding with least-privilege policies and stores
  credentials via the secret-vault skill.
---

# Cloud Provisioning

Interactive onboarding for AWS, Azure, and GCP compute credentials. Each cloud
walkthrough creates the minimum-viable credential with least-privilege scope, warns
at the exact moment when a one-time secret is shown, and hands off to secret-vault
for storage.

## Supported Clouds

Read the relevant reference file based on what the user needs:

- **AWS**: `references/aws-onboarding.md` — IAM user with programmatic access
- **Azure**: `references/azure-onboarding.md` — App Registration + Service Principal
- **GCP**: `references/gcp-onboarding.md` — Service Account with JSON key

If the user says "all three" or "set up everything", run them in sequence:
AWS → Azure → GCP.

## Onboarding Design Principles

1. **Least privilege** — no `AdministratorAccess`, `Owner`, or `Editor` roles.
   Each cloud gets a scoped policy/role limited to compute operations.
2. **One-time secret warning** — every cloud has a moment where the secret is shown
   exactly once. The onboarding marks this with a ⚠️ warning.
3. **Credential storage** — after capturing the credential, immediately store it
   via `secret-vault`: `python3 secret-vault/scripts/vault.py set <key> <value>`
4. **Verification** — each onboarding ends with a verification command that proves
   the credential works.

## Post-Onboarding

After onboarding, the user has:
- Credentials stored in secret-vault with keys like `aws.access_key_id`, `azure.client_id`, etc.
- A verification script: `scripts/verify-credentials.sh` that tests all configured clouds
- A reference card (printed at the end) showing env var names and vault keys

## Schemas

- `schemas/aws-compute-policy.json` — IAM policy for EC2/ECS/Lambda
- `schemas/azure-custom-role.json` — Azure custom role for compute operations
- `schemas/gcp-compute-role.yaml` — GCP IAM role binding

## Scripts

- `scripts/verify-credentials.sh` — Tests all three clouds in sequence
