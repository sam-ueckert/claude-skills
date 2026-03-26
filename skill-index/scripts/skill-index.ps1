# skill-index.ps1 — GitHub API skill index with caching
# Usage: skill-index.ps1 <list|search|show|refresh> [args]

param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$Arg1
)

$ErrorActionPreference = "Stop"

$Repo = if ($env:SKILL_INDEX_REPO) { $env:SKILL_INDEX_REPO } else { "ueckerts/claude-skills" }
$Branch = if ($env:SKILL_INDEX_BRANCH) { $env:SKILL_INDEX_BRANCH } else { "main" }
$CacheDir = Join-Path $HOME ".cache" "skill-index"
$CacheFile = Join-Path $CacheDir "$($Repo -replace '/', '_')_${Branch}.json"
$CacheTTL = 3600  # 1 hour in seconds
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VaultScript = Join-Path $ScriptDir ".." ".." "secret-vault" "scripts" "vault.py" | Resolve-Path -ErrorAction SilentlyContinue

if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

function Resolve-Token {
    if ($env:GITHUB_TOKEN) { return $env:GITHUB_TOKEN }
    if ($env:GH_TOKEN) { return $env:GH_TOKEN }
    if ($VaultScript -and (Test-Path $VaultScript)) {
        try {
            $token = & python3 $VaultScript get github.token 2>$null
            if ($token) { return $token }
        } catch {}
    }
    return $null
}

function Test-CacheFresh {
    if (-not (Test-Path $CacheFile)) { return $false }
    $age = ((Get-Date) - (Get-Item $CacheFile).LastWriteTime).TotalSeconds
    return $age -lt $CacheTTL
}

function Get-GithubHeaders {
    $headers = @{ "Accept" = "application/vnd.github+json" }
    $token = Resolve-Token
    if ($token) {
        $headers["Authorization"] = "Bearer $token"
    }
    return $headers
}

function Build-Index {
    $treeUrl = "https://api.github.com/repos/$Repo/git/trees/${Branch}?recursive=1"
    $headers = Get-GithubHeaders

    try {
        $response = Invoke-RestMethod -Uri $treeUrl -Headers $headers
    } catch {
        Write-Error "Failed to fetch repo tree. Is GITHUB_TOKEN set for private repos?"
        exit 1
    }

    if ($response.message) {
        Write-Error "$($response.message) - set GITHUB_TOKEN or GH_TOKEN for private repos"
        exit 1
    }

    $paths = $response.tree | Where-Object { $_.path -match '^[^/]+/SKILL\.md$' } | Select-Object -ExpandProperty path

    if (-not $paths) {
        "[]" | Set-Content -Path $CacheFile
        return
    }

    $results = @()
    foreach ($path in $paths) {
        $skillName = ($path -split '/')[0]
        $rawUrl = "https://raw.githubusercontent.com/$Repo/$Branch/$path"

        try {
            $content = Invoke-RestMethod -Uri $rawUrl -Headers $headers
        } catch {
            continue
        }

        # Parse YAML frontmatter
        $name = $skillName
        $desc = ""
        if ($content -match '(?s)^---\r?\n(.+?)\r?\n---') {
            $fm = $Matches[1]
            if ($fm -match '(?m)^name:\s*"?([^"\r\n]+)"?') { $name = $Matches[1].Trim() }
            if ($fm -match '(?m)^description:\s*"?([^"\r\n]+)"?') { $desc = $Matches[1].Trim() }
        }

        $results += @{ directory = $skillName; name = $name; description = $desc }
    }

    $results | ConvertTo-Json -Depth 5 | Set-Content -Path $CacheFile
}

function Ensure-Index {
    if (-not (Test-CacheFresh)) {
        Build-Index
    }
}

function Invoke-List {
    Ensure-Index
    $skills = Get-Content $CacheFile | ConvertFrom-Json
    foreach ($s in $skills) {
        Write-Output "  $($s.name)"
        Write-Output "    $($s.description)"
        Write-Output ""
    }
}

function Invoke-Search {
    if (-not $Arg1) {
        Write-Error "Usage: skill-index.ps1 search <query>"
        exit 1
    }
    Ensure-Index
    $query = $Arg1.ToLower()
    $skills = Get-Content $CacheFile | ConvertFrom-Json
    foreach ($s in $skills) {
        if ($s.name.ToLower().Contains($query) -or $s.description.ToLower().Contains($query)) {
            Write-Output "  $($s.name)"
            Write-Output "    $($s.description)"
            Write-Output ""
        }
    }
}

function Invoke-Show {
    if (-not $Arg1) {
        Write-Error "Usage: skill-index.ps1 show <skill-name>"
        exit 1
    }
    $rawUrl = "https://raw.githubusercontent.com/$Repo/$Branch/$Arg1/SKILL.md"
    $headers = Get-GithubHeaders
    try {
        $content = Invoke-RestMethod -Uri $rawUrl -Headers $headers
        Write-Output $content
    } catch {
        Write-Error "Skill '$Arg1' not found in $Repo"
        exit 1
    }
}

function Invoke-Refresh {
    if (Test-Path $CacheFile) { Remove-Item $CacheFile }
    Build-Index
    $skills = Get-Content $CacheFile | ConvertFrom-Json
    $count = if ($skills -is [array]) { $skills.Count } else { 1 }
    Write-Output "Refreshed index: $count skills found in $Repo ($Branch)"
}

switch ($Command) {
    "list"    { Invoke-List }
    "search"  { Invoke-Search }
    "show"    { Invoke-Show }
    "refresh" { Invoke-Refresh }
    default {
        @"
Usage: skill-index.ps1 <command> [args]

Commands:
  list              List all available skills
  search <query>    Search skills by keyword
  show <name>       Show full SKILL.md for a skill
  refresh           Force refresh the cached index
"@
    }
}
