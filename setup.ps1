# Setup script for Claude Code skills on Windows
# Usage: powershell -ExecutionPolicy Bypass -File setup.ps1
#
# Run from within the cloned repo.

$ErrorActionPreference = "Stop"

# Resolve repo root
$RepoDir = if ($env:SKILLS_DIR) { $env:SKILLS_DIR } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not (Test-Path "$RepoDir\setup.ps1")) {
    Write-Host "Run this script from within the claude-skills repo, or set SKILLS_DIR." -ForegroundColor Red
    exit 1
}

$ClaudeSkills = "$env:USERPROFILE\.claude\skills"

function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!!] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "  [XX] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  Claude Code Skills - Windows Setup" -ForegroundColor Cyan
Write-Host ("=" * 44)
Write-Host ""

# -- Prerequisites --
Write-Host "Checking prerequisites..."

try { $nodeVer = node --version; Write-Ok "Node.js $nodeVer" }
catch {
    Write-Fail "Node.js not found. Install from https://nodejs.org or: winget install OpenJS.NodeJS.LTS"
    exit 1
}

try { $npmVer = npm --version; Write-Ok "npm $npmVer" }
catch { Write-Fail "npm not found"; exit 1 }

try { $gitVer = git --version; Write-Ok $gitVer }
catch {
    Write-Fail "git not found. Install from https://git-scm.com or: winget install Git.Git"
    exit 1
}

try { $pyVer = python3 --version; Write-Ok $pyVer }
catch {
    try { $pyVer = python --version; Write-Ok $pyVer }
    catch { Write-Warn "Python not found - secret-vault skill will not work" }
}

Write-Host ""

# -- Install npm dependencies --
Write-Host "Installing dependencies..."

$mmdc = Get-Command mmdc -ErrorAction SilentlyContinue
if ($mmdc) {
    Write-Ok "mermaid-cli already installed"
} else {
    Write-Host "  Installing @mermaid-js/mermaid-cli (this may take a minute)..."
    npm install -g @mermaid-js/mermaid-cli 2>&1 | Select-Object -Last 3
    if ($LASTEXITCODE -eq 0) { Write-Ok "mermaid-cli installed" }
    else { Write-Warn "mermaid-cli install failed - try: npm install -g @mermaid-js/mermaid-cli" }
}

$defuddle = Get-Command defuddle -ErrorAction SilentlyContinue
if ($defuddle) {
    Write-Ok "defuddle already installed"
} else {
    Write-Host "  Installing defuddle..."
    npm install -g defuddle 2>&1 | Select-Object -Last 3
    if ($LASTEXITCODE -eq 0) { Write-Ok "defuddle installed" }
    else { Write-Warn "defuddle install failed - try: npm install -g defuddle" }
}

# Python cryptography for secret-vault
try {
    python3 -c "import cryptography" 2>$null
    Write-Ok "cryptography package installed"
} catch {
    try {
        python -c "import cryptography" 2>$null
        Write-Ok "cryptography package installed"
    } catch {
        Write-Host "  Installing cryptography for secret-vault..."
        pip3 install cryptography 2>&1 | Select-Object -Last 3
        if ($LASTEXITCODE -eq 0) { Write-Ok "cryptography installed" }
        else { Write-Warn "cryptography install failed - try: pip install cryptography" }
    }
}

Write-Host ""

# -- Link skills into Claude Code --
# Auto-discover skills: any directory containing a SKILL.md
# Uses directory junctions (no admin required)
Write-Host "Linking skills into Claude Code (~\.claude\skills\)..."
New-Item -ItemType Directory -Path $ClaudeSkills -Force | Out-Null

Get-ChildItem -Path $RepoDir -Directory | ForEach-Object {
    $skillDir = $_.FullName
    $skillMd = Join-Path $skillDir "SKILL.md"
    if (Test-Path $skillMd) {
        $skill = $_.Name
        $target = Join-Path $ClaudeSkills $skill
        if (Test-Path $target) { Remove-Item $target -Recurse -Force }
        cmd /c mklink /J "$target" "$skillDir" | Out-Null
        Write-Ok $skill
    }
}

Write-Host ""

# -- Verify --
Write-Host "Verifying..."

$testFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.mmd'
"graph LR`n    A[Setup] --> B[Complete]" | Out-File -FilePath $testFile -Encoding utf8
$outFile = $testFile -replace '\.mmd$', '.png'

$mmdc = Get-Command mmdc -ErrorAction SilentlyContinue
if ($mmdc) {
    mmdc -i $testFile -o $outFile -t dark 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Ok "Mermaid rendering works" }
    else { Write-Warn "Mermaid rendering failed - try: npx puppeteer browsers install chrome" }
}
Remove-Item $testFile, $outFile -ErrorAction SilentlyContinue

# List final state
Write-Host ""
Write-Host ("=" * 44)
Write-Host "  Installed Skills" -ForegroundColor Cyan
Write-Host ("=" * 44)
Get-ChildItem $ClaudeSkills -Directory | ForEach-Object {
    $name = $_.Name
    $target = if ($_.LinkTarget) { $_.LinkTarget } else { "local" }
    $target = $target -replace [regex]::Escape($env:USERPROFILE), '~'
    Write-Host ("  [OK] /{0,-20} -> {1}" -f $name, $target) -ForegroundColor Green
}

Write-Host ""
Write-Host ("=" * 44)
Write-Host "  Done! Restart Claude Code to pick up skills." -ForegroundColor Green
Write-Host "  Type / to see available skills."
Write-Host ("=" * 44)
