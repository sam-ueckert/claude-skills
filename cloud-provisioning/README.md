# Cloud Provisioning

Interactive onboarding for AWS, Azure, and GCP compute credentials with least-privilege IAM policies.

## Quick Start

Ask Claude:

> "Set up my AWS credentials for compute automation"

Or onboard all three:

> "Onboard me to AWS, Azure, and GCP"

## What Happens During Onboarding

Each cloud walkthrough:
1. Guides you through creating a least-privilege credential in the cloud console
2. Warns you at the exact moment the one-time secret appears (⚠️ copy it NOW)
3. Stores the credential in secret-vault
4. Verifies the credential works

## Included Policies

| Cloud | File | Scope |
|-------|------|-------|
| AWS | `schemas/aws-compute-policy.json` | EC2, ECS, Lambda — scoped to us-east-1/us-west-2 |
| Azure | `schemas/azure-custom-role.json` | VMs, Container Instances, AKS — scoped to resource group |
| GCP | `schemas/gcp-compute-role.yaml` | Compute Engine, Cloud Run, Cloud Functions — project level |

## Verification

```bash
bash scripts/verify-credentials.sh
```

Tests all configured clouds and reports pass/fail/skip for each.
