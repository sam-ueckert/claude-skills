# PB-OPS-001: Azure AI Foundry Model Deployment

| Field | Value |
|-------|-------|
| Author | Automation Team |
| Version | 1.0 |
| Last Reviewed | 2025-03-25 |
| Approval | Draft |

## Purpose

Deploy a fine-tuned model to Azure AI Foundry (formerly Azure AI Studio) with
managed endpoint provisioning and traffic routing.

## Scope

Azure AI Foundry projects in the production subscription. Covers model registration,
endpoint creation, deployment, and smoke testing.

## Prerequisites

- Azure CLI authenticated with `Contributor` role on the target resource group
- Model artifacts uploaded to the project's storage account
- Endpoint quota confirmed via `az ml online-endpoint list-skus`
- `secret-vault` configured with `azure.client_id`, `azure.client_secret`, `azure.tenant_id`

## Procedure

### Step 1: Authenticate to Azure
- **Action**: Run `az login --service-principal` using credentials from secret-vault
- **Role**: Deployer
- **Expected Outcome**: `az account show` returns the target subscription
- **If Failed**: Verify credentials with `vault.py get azure.client_id` and check Azure AD

### Step 2: Register the model
- **Action**: Register the model artifact with `az ml model create`
- **Role**: Deployer
- **Expected Outcome**: Model appears in `az ml model list` with correct version
- **If Failed**: Check storage permissions and artifact path

### Step 3: Create or update managed endpoint
- **Action**: Create endpoint with `az ml online-endpoint create --name <endpoint>`
- **Role**: Deployer
- **Expected Outcome**: Endpoint status is `Succeeded`
- **Duration Estimate**: 3-5 minutes

### Step 4: Deploy model to endpoint
- **Action**: Run `az ml online-deployment create` with instance type and scale settings
- **Role**: Deployer
- **Expected Outcome**: Deployment status is `Succeeded`, health probe passes
- **Duration Estimate**: 10-15 minutes
- **If Failed**: Check quota limits, review deployment logs

### Step 5: Route traffic
- **Action**: Update traffic split with `az ml online-endpoint update --traffic`
- **Role**: Deployer
- **Expected Outcome**: 100% traffic on new deployment (or canary split as specified)

### Step 6: Smoke test
- **Action**: Send test request to endpoint scoring URI
- **Role**: Deployer
- **Expected Outcome**: HTTP 200 with valid model output

## Rollback Procedure

1. Route 100% traffic back to previous deployment
2. Delete the new deployment with `az ml online-deployment delete`
3. If model registration was wrong, archive with `az ml model archive`

## Verification

- Endpoint returns HTTP 200 for test payload
- Azure Monitor shows no 5xx errors in the first 15 minutes
- Model version in endpoint details matches expected version

## Deviations from Standard

None
