#!/usr/bin/env bash
# verify-credentials.sh — Test all configured cloud credentials
# Reads from secret-vault or environment variables

set -euo pipefail

VAULT_SCRIPT="$(dirname "$0")/../secret-vault/scripts/vault.py"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
skip() { echo -e "  ${YELLOW}⊘${NC} $1 (skipped — credentials not configured)"; }

# Helper: get secret from vault or env
get_secret() {
    local key="$1"
    local env_var="$2"
    if [ -f "$VAULT_SCRIPT" ]; then
        python3 "$VAULT_SCRIPT" get "$key" 2>/dev/null || echo "${!env_var:-}"
    else
        echo "${!env_var:-}"
    fi
}

echo "=== Cloud Credential Verification ==="
echo ""

# --- AWS ---
echo "AWS:"
AWS_KEY=$(get_secret "aws.access_key_id" "AWS_ACCESS_KEY_ID")
if [ -n "$AWS_KEY" ]; then
    if aws sts get-caller-identity &>/dev/null; then
        ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
        pass "Authenticated to account $ACCOUNT"
    else
        fail "Credentials present but authentication failed"
    fi
else
    skip "aws.access_key_id"
fi
echo ""

# --- Azure ---
echo "Azure:"
AZ_CLIENT=$(get_secret "azure.client_id" "AZURE_CLIENT_ID")
if [ -n "$AZ_CLIENT" ]; then
    AZ_SECRET=$(get_secret "azure.client_secret" "AZURE_CLIENT_SECRET")
    AZ_TENANT=$(get_secret "azure.tenant_id" "AZURE_TENANT_ID")
    if az login --service-principal -u "$AZ_CLIENT" -p "$AZ_SECRET" --tenant "$AZ_TENANT" &>/dev/null; then
        SUB=$(az account show --query "name" -o tsv 2>/dev/null)
        pass "Authenticated to subscription: $SUB"
        az logout &>/dev/null
    else
        fail "Credentials present but authentication failed"
    fi
else
    skip "azure.client_id"
fi
echo ""

# --- GCP ---
echo "GCP:"
GCP_KEY_FILE=$(get_secret "gcp.key_file_path" "GOOGLE_APPLICATION_CREDENTIALS")
if [ -n "$GCP_KEY_FILE" ] && [ -f "$GCP_KEY_FILE" ]; then
    if gcloud auth activate-service-account --key-file="$GCP_KEY_FILE" &>/dev/null; then
        PROJECT=$(gcloud config get-value project 2>/dev/null)
        pass "Authenticated to project: $PROJECT"
        gcloud auth revoke --quiet &>/dev/null 2>&1 || true
    else
        fail "Key file present but authentication failed"
    fi
else
    skip "gcp.key_file_path"
fi

echo ""
echo "=== Done ==="
