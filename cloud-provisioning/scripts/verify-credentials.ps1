# verify-credentials.ps1 — Test all configured cloud credentials
# Reads from secret-vault or environment variables

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VaultScript = Join-Path $ScriptDir ".." "secret-vault" "scripts" "vault.py"
if (-not (Test-Path $VaultScript -ErrorAction SilentlyContinue)) { $VaultScript = $null }

function Get-Secret {
    param(
        [string]$Key,
        [string]$EnvVar
    )
    if ($VaultScript) {
        try {
            $val = & python3 $VaultScript get $Key 2>$null
            if ($val) { return $val }
        } catch {}
    }
    return [System.Environment]::GetEnvironmentVariable($EnvVar)
}

function Write-Pass  { param([string]$Msg) Write-Host "  " -NoNewline; Write-Host "[PASS]" -ForegroundColor Green -NoNewline; Write-Host " $Msg" }
function Write-Fail  { param([string]$Msg) Write-Host "  " -NoNewline; Write-Host "[FAIL]" -ForegroundColor Red -NoNewline; Write-Host " $Msg" }
function Write-Skip  { param([string]$Msg) Write-Host "  " -NoNewline; Write-Host "[SKIP]" -ForegroundColor Yellow -NoNewline; Write-Host " $Msg (skipped - credentials not configured)" }

Write-Host "=== Cloud Credential Verification ==="
Write-Host ""

# --- AWS ---
Write-Host "AWS:"
$awsKey = Get-Secret -Key "aws.access_key_id" -EnvVar "AWS_ACCESS_KEY_ID"
if ($awsKey) {
    try {
        $null = & aws sts get-caller-identity 2>$null
        if ($LASTEXITCODE -eq 0) {
            $account = & aws sts get-caller-identity --query "Account" --output text 2>$null
            Write-Pass "Authenticated to account $account"
        } else {
            Write-Fail "Credentials present but authentication failed"
        }
    } catch {
        Write-Fail "Credentials present but authentication failed"
    }
} else {
    Write-Skip "aws.access_key_id"
}
Write-Host ""

# --- Azure ---
Write-Host "Azure:"
$azClient = Get-Secret -Key "azure.client_id" -EnvVar "AZURE_CLIENT_ID"
if ($azClient) {
    $azSecret = Get-Secret -Key "azure.client_secret" -EnvVar "AZURE_CLIENT_SECRET"
    $azTenant = Get-Secret -Key "azure.tenant_id" -EnvVar "AZURE_TENANT_ID"
    try {
        $null = & az login --service-principal -u $azClient -p $azSecret --tenant $azTenant 2>$null
        if ($LASTEXITCODE -eq 0) {
            $sub = & az account show --query "name" -o tsv 2>$null
            Write-Pass "Authenticated to subscription: $sub"
            & az logout 2>$null | Out-Null
        } else {
            Write-Fail "Credentials present but authentication failed"
        }
    } catch {
        Write-Fail "Credentials present but authentication failed"
    }
} else {
    Write-Skip "azure.client_id"
}
Write-Host ""

# --- GCP ---
Write-Host "GCP:"
$gcpKeyFile = Get-Secret -Key "gcp.key_file_path" -EnvVar "GOOGLE_APPLICATION_CREDENTIALS"
if ($gcpKeyFile -and (Test-Path $gcpKeyFile -ErrorAction SilentlyContinue)) {
    try {
        $null = & gcloud auth activate-service-account --key-file=$gcpKeyFile 2>$null
        if ($LASTEXITCODE -eq 0) {
            $project = & gcloud config get-value project 2>$null
            Write-Pass "Authenticated to project: $project"
            & gcloud auth revoke --quiet 2>$null | Out-Null
        } else {
            Write-Fail "Key file present but authentication failed"
        }
    } catch {
        Write-Fail "Key file present but authentication failed"
    }
} else {
    Write-Skip "gcp.key_file_path"
}

Write-Host ""
Write-Host "=== Done ==="
