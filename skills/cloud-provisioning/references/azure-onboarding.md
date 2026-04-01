# Azure Onboarding — App Registration + Service Principal

This guide creates an Azure App Registration and Service Principal with a custom compute automation role. By the end, you'll have `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, and `AZURE_TENANT_ID` the skill can use.

---

## Role Used

The custom role from `schemas/azure-custom-role.json` grants:
- **Virtual Machines:** read, start, restart, deallocate, write, delete
- **Container Instances:** full access to container groups
- **AKS:** read clusters, list user credentials
- **Resource Groups:** read
- **Networking:** full NSG access, read VNets/subnets

The role is scoped to a specific resource group (see `AssignableScopes`).

---

## Option A: Azure Portal

### 1. Create the App Registration

1. Sign in to the [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **App registrations** → **New registration**
3. Name it `agent-compute-automation`
4. Leave "Supported account types" as **Single tenant**
5. No redirect URI needed → **Register**
6. Note the **Application (client) ID** and **Directory (tenant) ID** from the Overview page

### 2. Create a Client Secret

1. In the app registration, go to **Certificates & secrets** → **Client secrets** → **New client secret**
2. Add a description: `agent-compute-key`
3. Set expiry — recommended **6 months** (the portal default is 24 months; override it)
4. Click **Add**

> ⚠️ **ONE-TIME WARNING:** The secret value is only shown immediately after creation. Copy it now — it will be masked as `***` the next time you view this page.

5. Save the **Value** (not the Secret ID) as `AZURE_CLIENT_SECRET`

### 3. Create the Custom Role

1. Navigate to your **Subscription** or **Resource Group** → **Access control (IAM)** → **Add** → **Add custom role**
2. Select **Start from JSON** and upload/paste the contents of `schemas/azure-custom-role.json`
3. Update `AssignableScopes` to your actual subscription/resource group:
   ```
   /subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/YOUR-RESOURCE-GROUP
   ```
4. Click **Review + create** → **Create**

### 4. Assign the Role to the Service Principal

1. Go to your **Resource Group** → **Access control (IAM)** → **Add role assignment**
2. Search for **Agent Compute Automation** (the custom role you just created)
3. Under **Members**, select **User, group, or service principal**
4. Search for `agent-compute-automation` and select it
5. Click **Review + assign** → **Assign**

---

## Option B: Azure CLI

```bash
# Set variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="your-resource-group"
APP_NAME="agent-compute-automation"

# 1. Create the App Registration + Service Principal
APP=$(az ad app create --display-name "$APP_NAME")
APP_ID=$(echo $APP | jq -r '.appId')
az ad sp create --id "$APP_ID"

echo "Client ID (AZURE_CLIENT_ID): $APP_ID"
echo "Tenant ID (AZURE_TENANT_ID): $(az account show --query tenantId -o tsv)"

# 2. Create client secret (6-month expiry)
# ⚠️ Save the output immediately — the password is never shown again
az ad app credential reset \
  --id "$APP_ID" \
  --years 0.5 \
  --query password \
  -o tsv

# 3. Create the custom role (update AssignableScopes first)
# Edit the JSON to replace {subscription-id} and {resource-group}
sed -i "s/{subscription-id}/$SUBSCRIPTION_ID/g; s/{resource-group}/$RESOURCE_GROUP/g" \
  skills/cloud-provisioning/schemas/azure-custom-role.json

az role definition create \
  --role-definition @skills/cloud-provisioning/schemas/azure-custom-role.json

# 4. Assign the role to the service principal
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Agent Compute Automation" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
```

---

## Verification

```bash
# Log in as the service principal
az login --service-principal \
  --username "$AZURE_CLIENT_ID" \
  --password "$AZURE_CLIENT_SECRET" \
  --tenant "$AZURE_TENANT_ID"

# List VMs in the resource group (empty list is fine — means auth worked)
az vm list --resource-group "$RESOURCE_GROUP" -o table

# Log back out when done testing
az logout
```

---

## Gotchas

### Forgetting to Grant Admin Consent
If your Azure AD tenant requires admin consent for API permissions, the service principal may get `Unauthorized` errors even after role assignment. In the portal, go to **App registrations** → your app → **API permissions** → **Grant admin consent for [tenant]**.

For purely resource-level RBAC (no Graph API), this usually isn't needed — but it's a common surprise when adding Microsoft Graph permissions later.

### Client Secret Expiry — Default Is 24 Months, Not 6
The portal defaults to **24 months** (2 years). This is easy to miss. Set a calendar reminder when you create the secret, or use a shorter duration:
- **Portal:** explicitly choose Custom or 6 months in the dropdown
- **CLI:** use `--years 0.5` for 6 months

Expired secrets cause silent auth failures. Always track expiry dates.

### Role Assignment Propagation Delay
Azure RBAC assignments can take **up to 5 minutes** to propagate. If you immediately test and get `AuthorizationFailed`, wait a few minutes and retry.

### AssignableScopes Must Be Updated
The `AssignableScopes` in `schemas/azure-custom-role.json` contains placeholder values (`{subscription-id}`, `{resource-group}`). The role creation will fail if these are not replaced with real values before deployment.

### Custom Role Name Uniqueness
Azure custom role names must be unique within a tenant. If you get a conflict error, the role may already exist from a previous run — use `az role definition list --name "Agent Compute Automation"` to check.

### Service Principal vs Managed Identity
For workloads running inside Azure (VMs, App Service, etc.), prefer **Managed Identities** over service principals — no secrets to rotate. Service principals are appropriate for external tools and CI/CD.
